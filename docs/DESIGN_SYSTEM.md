# Design System

Source of truth: the HTML mockups in **SERDEN APP FINAL DESIGN** (rebrand,
July 2026). The old teal Figma palette is retired.

Flutter implementation: `lib/core/theme/`

---

## Colors

Dart class: `AppColors` in `lib/core/theme/app_colors.dart`

### Brand greens
| Token | Hex | Usage |
|---|---|---|
| `AppColors.green900` | `#0F2D20` | Deepest backdrop (behind sheets) |
| `AppColors.green800` | `#153A2B` | Headers, active nav, dark cards. Alias: `primary` |
| `AppColors.green700` | `#1E4A37` | Onboarding panels, focused field border |
| `AppColors.greenDeep` | `#1E5C3F` | Links, positive accents, switch-on, progress fill |
| `AppColors.greenTint` | `#E4F0E9` | Green icon chips, success chip bg |

### Brand orange (primary CTA)
| Token | Hex | Usage |
|---|---|---|
| `AppColors.orange500` | `#E2793A` | CTAs, FABs, notification dots. Alias: `accent` |
| `AppColors.orange600` | `#C96528` | Pressed/hover CTA |
| `AppColors.orangeTint` | `#FDEBDD` | Warning banners, "viewed" chips |
| `AppColors.orangeDeep` | `#9C4A15` | Text/icons on orangeTint |

### Status tints
| Token | Hex | Usage |
|---|---|---|
| `AppColors.redTint` / `redDeep` | `#FBE9E7` / `#A33A2A` | Declined, overdue, destructive |
| `AppColors.grayTint` / `grayDeep` | `#EEEFEE` / `#6A756E` | Sent/draft chips, neutral icon chips |

### Surfaces & ink
| Token | Hex | Usage |
|---|---|---|
| `AppColors.page` | `#F7F7F5` | Scaffold background. Alias: `background` |
| `AppColors.card` | `#FFFFFF` | Cards, rows, sheets. Alias: `surface` |
| `AppColors.sheetBg` | `#FAFAF8` | Auth bottom sheet |
| `AppColors.ink` | `#1B2B23` | Primary text. Alias: `textPrimary` |
| `AppColors.inkSoft` | `#5C6B62` | Secondary text. Alias: `textSecondary` |
| `AppColors.inkFaint` | `#93A099` | Metadata, placeholders. Alias: `textHint` |
| `AppColors.line` | `#ECEEEC` | Hairline borders/dividers. Alias: `border` |
| `AppColors.fieldBorder` | `#D8DDD9` | Auth input borders, switch track off |
| `AppColors.star` | `#EFA727` | Review stars |

### Document (paper preview)
`docInk #1C1C1E`, `docSoft #3A3A3C`, `docNavy #2E3A55` (logo), `docLine #E5E5E3`,
`docSectionBg #EFEFED` — used only inside estimate/invoice paper pages.

### Avatars
`AppColors.avatarColors` — 6-color palette, hash-picked per client name via
`AvatarWidget.colorFor` (same hash as the mockups).

---

## Typography

Font: **Manrope** (bundled in `assets/fonts/`, weights 500/600/700/800).
Dart class: `AppTextStyles` in `lib/core/theme/app_text_styles.dart`

| Style | Size / weight | Usage |
|---|---|---|
| `headerTitle` | 26 / 800 | List screen titles on green header |
| `headerSubtitle` | 13 / 500 white-68% | Header subtitle line |
| `displayLarge` | 28 / 800 | Onboarding headlines |
| `headingMedium` | 22 / 800 | Empty-state / welcome titles |
| `headingSmall` | 16 / 800 | Form nav titles |
| `rowTitle` | 15 / 700 | List row names |
| `rowAmount` | 15.5 / 800 | Amounts in rows |
| `sectionLabel` | 12.5 / 700 uppercase | Grey section labels |
| `caption` | 12.5 / 500 faint | Row metadata |
| `chip` | 11 / 700 | Status chips |
| `buttonText` | 16 / 700 | Orange CTAs |

---

## Core patterns

- **Screen chrome:** dark green (`green800`) header block with 26/800 title,
  subtitle with bold highlights, 38px translucent icon buttons, optional
  translucent search bar (`AppHeader`, `HeaderSearchBar`, `HeaderIconButton`
  in `core/widgets/main_shell.dart`).
- **Detail chrome:** compact green header with back label (`DetailHeader`),
  uppercase tool button row (`DocumentToolbar`), tinted `StatusBand`.
- **Tabs:** underline tab strip on a white bar (`PillTabs`) — equal-width
  labels with a small count badge and an animated 2.5px underline indicator.
  Active label + indicator are green800 (red for Overdue, orange for new Leads).
- **Cards:** white, radius 14, 1px `line` border (`AppCard`, `CardRow`).
- **Status chips:** tinted pills with 11px icon + 11/700 label (`StatusChip`).
- **FAB:** orange extended pill, radius 14, soft orange shadow (`AppFab`).
- **Forms:** white top bar Cancel · title · Save (`FormNavBar`); fields are
  page-tinted inputs with radius 11 and greenDeep focus border.
- **Modals/pickers:** bottom sheets with a 40x4 grabber.
- **Documents:** letter-size paper preview at 816px scaled to fit (Desktop)
  or reflowed naturally (Mobile) — `lib/shared/widgets/paper_document.dart`.
- **New estimate / invoice:** one shared form —
  `lib/shared/widgets/document_form.dart`.

## Bottom nav tabs (in order)

Estimates · Invoices · Clients · **Leads** · More
(Payments is no longer a tab; payments are recorded from an invoice via
`/invoices/:id/record-payment`.)
