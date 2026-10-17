#!/usr/bin/env python3
"""生成报告 PDF 用的中文字体子集（stats-flutter v1.5.0 M4.2b）。

为什么需要它：`pdf` 包渲染中文必须自带字体文件，而完整 Noto Sans SC 可变字体
有 ~17MB（四平台产物都要 +17MB）。这里按需子集化到「GB2312 汉字 + 拉丁 + 希腊 +
常用标点/数学/全角」约 3~5MB，并按 OFL 要求改名为 `StatsSansSC`（与上游 Noto
区分，避免有人把子集当完整字体用）。

依赖：`pip install fonttools`（4.63+）。

用法：
  python tools/subset_cjk_font.py \
      --src "NotoSansSC[wght].ttf" \
      --out assets/fonts/StatsSansSC-Regular.ttf

进度/结论：
- 输入 NotoSansSC[wght].ttf 17,772,300 B / 31,036 字形（wght 100..900）
- 输出见脚本结尾打印（字节数、字形数、抽查缺字）

局限：繁体、生僻字不在 GB2312 内，PDF 里会缺字（显示为空白）；
需要完整保真时用 HTML 导出，或把 `--extra` 指到一个补字文件再跑一次。
"""

from __future__ import annotations

import argparse
import os
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

# 除 GB2312 汉字外一并保留的 Unicode 区段（报告里的 α β χ² ≥ ≤ × − ① 等）
RANGES: list[tuple[int, int]] = [
    (0x0020, 0x007E),  # ASCII
    (0x00A0, 0x024F),  # Latin-1 补充 + 扩展 A/B
    (0x0370, 0x03FF),  # 希腊字母（α β χ φ η ω）
    (0x2000, 0x206F),  # 常用标点（– — ‘ ’ “ ” … † ‡ • ‰ ′ ″ ⁄）
    (0x2070, 0x209F),  # 上下标（² ³ ₁ ₂）
    (0x20A0, 0x20BF),  # 货币符号
    (0x2100, 0x214F),  # 字母式符号（ℓ № ™）
    (0x2190, 0x21FF),  # 箭头
    (0x2200, 0x22FF),  # 数学运算符（∑ √ ∞ ∝ ∴ ≤ ≥ ≠ ≈ ≡）
    (0x2460, 0x24FF),  # 带圈数字 / 括号字母
    (0x25A0, 0x25FF),  # 几何图形（■ □ ● ○ ◆ ★）
    (0x2600, 0x26FF),  # 杂项符号（★ ☆）
    (0x3000, 0x303F),  # CJK 标点（、。〈〉《》「」）
    (0xFF00, 0xFFEF),  # 全角形式（Ａ１，（））
]


def gb2312_unicodes() -> set[int]:
    """GB2312 全部码位（汉字 + 符号区）。"""
    out: set[int] = set()
    for hi in range(0xA1, 0xF8):
        for lo in range(0xA1, 0xFF):
            try:
                char = bytes([hi, lo]).decode("gb2312")
            except UnicodeDecodeError:
                continue
            out.add(ord(char))
    return out


def rename(font: TTFont, family: str) -> None:
    """按 OFL-1.1 要求改名：子集不得再叫 Noto。"""
    ps = family.replace(" ", "")
    for rec in font["name"].names:
        if rec.nameID in (1, 16):
            rec.string = family
        elif rec.nameID in (2, 17):
            rec.string = "Regular"
        elif rec.nameID == 3:
            rec.string = f"{ps}-Regular; subset of Noto Sans SC"
        elif rec.nameID == 4:
            rec.string = f"{family} Regular"
        elif rec.nameID == 6:
            rec.string = f"{ps}-Regular"


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--src", required=True, help="NotoSansSC[wght].ttf 路径")
    ap.add_argument("--out", required=True, help="输出 ttf 路径")
    ap.add_argument("--weight", type=float, default=400, help="静态实例化的字重")
    ap.add_argument("--family", default="StatsSansSC", help="改名后的字族名")
    ap.add_argument("--extra", help="额外补字文件（每行若干字符，可选）")
    args = ap.parse_args(argv)

    if not os.path.exists(args.src):
        print(f"找不到源字体：{args.src}", file=sys.stderr)
        return 2

    unicodes = gb2312_unicodes()
    for lo, hi in RANGES:
        unicodes.update(range(lo, hi + 1))
    if args.extra:
        with open(args.extra, encoding="utf-8") as fh:
            for line in fh:
                unicodes.update(ord(c) for c in line.strip())

    src_size = os.path.getsize(args.src)
    font = TTFont(args.src)
    src_glyphs = font["maxp"].numGlyphs

    # 1) 可变字体 → 静态实例（报告只用 Regular）
    font = instancer.instantiateVariableFont(
        font, {"wght": args.weight}, inplace=False, updateFontNames=False
    )

    # 2) 子集化
    opts = subset.Options()
    opts.name_IDs = ["*"]
    opts.name_legacy = True
    opts.name_languages = ["*"]
    opts.notdef_outline = True
    opts.recalc_bounds = True
    opts.drop_tables += ["BASE", "vhea", "vmtx"]  # 竖排 / 基线表用不到
    sub = subset.Subsetter(options=opts)
    sub.populate(unicodes=unicodes)
    sub.subset(font)

    # 3) 改名
    rename(font, args.family)

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    font.save(args.out)

    out_size = os.path.getsize(args.out)
    out = TTFont(args.out, lazy=True)
    out_glyphs = out["maxp"].numGlyphs
    cmap = out.getBestCmap()
    sample = "* 说明：样本 N=40，均值 3.14，SD 2.71，p<0.001，χ²=7.82，η²=0.13（①②③）"
    missing = sorted({c for c in sample if ord(c) not in cmap})
    print(f"输入 {args.src}  {src_size:,} B / {src_glyphs} 字形")
    print(f"输出 {args.out}  {out_size:,} B / {out_glyphs} 字形")
    print(f"压缩比 {src_size / max(out_size, 1):.1f}x")
    print("抽查缺字：", "无" if not missing else "".join(missing))
    print("字体名：", args.family, "| 表：", sorted(out.keys()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
