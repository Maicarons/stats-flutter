# Projects

The home tab is a **project list**. Each project is an independent statistical dataset.

## Project list

- **New demo project** — built-in scores & teaching-method sample
- **New blank project**
- Open / rename / duplicate / delete
- Search filter

Cards show name, case count, variable count, and last updated time.

## Persistence

Projects are stored as JSON under:

```
<app documents>/stats_flutter_projects/<id>.json
```

## Project workspace

Opening a project gives three tabs:

| Tab | Purpose |
|-----|---------|
| **Data** | spreadsheet, variable view, CSV, value labels |
| **Analysis** | statistical procedures |
| **Transform** | COMPUTE / RECODE / SORT … |

Learn / Quiz / Settings stay **global** and do not require a project.
