import { defineConfig } from 'vitepress'

// GitHub Project Pages: https://<user>.github.io/<repo>/
// base 必须是 /<repo>/，否则 CSS/JS 404（站点「无样式」的常见原因）
const base = '/stats-flutter/'

export default defineConfig({
  title: 'Stats-flutter',
  description: '工程化统计分析套件 · 灵感来自 GNU PSPP',
  base,
  cleanUrls: true,
  lastUpdated: true,
  // 构建产物相对 base，便于 Pages 托管
  ignoreDeadLinks: true,
  locales: {
    root: {
      label: '简体中文',
      lang: 'zh-CN',
      themeConfig: {
        nav: [
          { text: '指南', link: '/guide/getting-started' },
          { text: '功能', link: '/features/statistics' },
          { text: 'API', link: '/api/statkit' },
          { text: 'GitHub', link: 'https://github.com/Maicarons/stats-flutter' },
        ],
        sidebar: [
          {
            text: '指南',
            items: [
              { text: '快速开始', link: '/guide/getting-started' },
              { text: '工程管理', link: '/guide/projects' },
              { text: '数据编辑器', link: '/guide/data-editor' },
              { text: '统计分析', link: '/guide/analysis' },
              { text: '数据变换', link: '/guide/transforms' },
              { text: '学习与测试', link: '/guide/learn-quiz' },
            ],
          },
          {
            text: '功能详解',
            items: [
              { text: '统计过程', link: '/features/statistics' },
              { text: '设置与主题', link: '/features/settings' },
              { text: '国际化', link: '/features/i18n' },
            ],
          },
          {
            text: '开发',
            items: [
              { text: 'statkit API', link: '/api/statkit' },
              { text: '发布到 pub.dev', link: '/guide/publish-statkit' },
              { text: 'PSPP 研究纪要', link: '/research/pspp' },
            ],
          },
        ],
        outline: { label: '本页目录' },
        docFooter: { prev: '上一篇', next: '下一篇' },
        lastUpdatedText: '最后更新',
        darkModeSwitchLabel: '主题',
        sidebarMenuLabel: '菜单',
        returnToTopLabel: '回到顶部',
        search: {
          provider: 'local',
          options: {
            translations: {
              button: { buttonText: '搜索', buttonAriaLabel: '搜索' },
              modal: {
                noResultsText: '没有找到结果',
                resetButtonTitle: '清除',
                footer: {
                  selectText: '选择',
                  navigateText: '切换',
                  closeText: '关闭',
                },
              },
            },
          },
        },
      },
    },
    en: {
      label: 'English',
      lang: 'en-US',
      link: '/en/',
      themeConfig: {
        nav: [
          { text: 'Guide', link: '/en/guide/getting-started' },
          { text: 'Features', link: '/en/features/statistics' },
          { text: 'API', link: '/en/api/statkit' },
          { text: 'GitHub', link: 'https://github.com/Maicarons/stats-flutter' },
        ],
        sidebar: [
          {
            text: 'Guide',
            items: [
              { text: 'Getting Started', link: '/en/guide/getting-started' },
              { text: 'Projects', link: '/en/guide/projects' },
              { text: 'Data Editor', link: '/en/guide/data-editor' },
              { text: 'Analysis', link: '/en/guide/analysis' },
              { text: 'Transforms', link: '/en/guide/transforms' },
              { text: 'Learn & Quiz', link: '/en/guide/learn-quiz' },
            ],
          },
          {
            text: 'Features',
            items: [
              {
                text: 'Statistical Procedures',
                link: '/en/features/statistics',
              },
              { text: 'Settings & Theme', link: '/en/features/settings' },
              {
                text: 'Internationalization',
                link: '/en/features/i18n',
              },
            ],
          },
          {
            text: 'Development',
            items: [
              { text: 'statkit API', link: '/en/api/statkit' },
              { text: 'Publish to pub.dev', link: '/en/guide/publish-statkit' },
            ],
          },
        ],
      },
    },
  },
  themeConfig: {
    logo: '/logo.svg',
    socialLinks: [
      { icon: 'github', link: 'https://github.com/Maicarons/stats-flutter' },
    ],
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Inspired by GNU PSPP · Built with Flutter',
    },
  },
})
