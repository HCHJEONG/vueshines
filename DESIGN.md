# Vueshines Design Guidelines

## Recommended Pattern

Use a **Calm Academic Portal** pattern.

This is a structured education-service interface inspired by Korean online
learning products such as ETOOS: clean, trustworthy, content-forward, and
optimized for repeated study sessions. It should feel more like a focused LMS
than a startup landing page or experimental dashboard.

Do not use neo-brutalism for this project.

## UI Framework Direction

Use **PrimeVue + Tailwind CSS** as the preferred UI direction for future
frontend implementation. This project should keep the existing Vue/Vite shape
and avoid choices that make a later PrimeVue adoption awkward.

Guidelines:

- Prefer plain Vue components, scoped CSS, and Tailwind-compatible layout
  decisions until PrimeVue is formally introduced.
- Do not introduce Quasar, Vuetify, or another full application UI framework
  without explicit approval.
- Avoid framework-specific layout wrappers, theme assumptions, global resets,
  component abstractions, or naming patterns that would fight PrimeVue later.
- Use PrimeVue for common application controls when the dependency is added:
  buttons, inputs, selects, dialogs, tabs, badges, messages, and similar UI.
- Add TanStack Table only when the app reaches data-heavy screens that need
  sorting, filtering, pagination, row selection, or column composition beyond
  simple LMS lists. Do not add it for basic course or lecture lists.
- Tailwind CSS should carry page layout, spacing, responsive behavior, and
  small visual adjustments. PrimeVue should carry reusable interactive controls.
- Keep the visual result aligned with the Calm Academic Portal direction; do
  not accept a component library default theme if it makes the app feel generic
  or overly constrained.

## Course Detail Pattern

For course, service detail, and enrollment pages, use a **Structured Enrollment
Detail** layout inside the Calm Academic Portal direction.

The page should communicate trust, clarity, order, and high readability. A user
should be able to confirm the course identity, understand the key conditions,
select required or optional items, and enroll without hunting through the page.

Use this page structure:

1. Title area
2. Two-column information area
3. Enrollment option and final action area

### Title Area

- Show category or subject tags first.
- Place the main course or service title immediately below.
- Make the title visually dominant enough that the user can recognize the page
  within one second.
- Keep supporting labels compact.

### Two-Column Information Area

- On desktop, use a left visual anchor and right information grid.
- The left side should contain the teacher image, service thumbnail, or official
  course visual.
- Use clean, trustworthy imagery. Prefer clear cutout-style teacher photos,
  official thumbnails, or restrained education graphics.
- The right side should use a label/value information grid.
- Align labels consistently and separate rows with light gray dividers.
- Good metadata examples:
  `강좌유형`, `강좌구성`, `수강기간`, `교재정보`, `대상학년`, `선생님`.
- Place a wide secondary CTA below the information grid when useful, such as
  `구독권 신청` or `빠른 신청`.
- The secondary CTA should support the decision flow without competing with the
  final purchase/enrollment button.

### Enrollment Options

- Place required course items and optional textbook or add-on items below the
  information area.
- Use checkboxes for independently selectable purchase items.
- Each row should show selection state, item name, and price.
- Keep names readable when long:
  allow natural wrapping or use a deliberate two-line clamp.
- Prices should align to the right on desktop.
- Use tabular numbers where possible.

### Final Action Area

- Place final actions near the lower-right end of the enrollment section on
  desktop.
- Show `장바구니` and `구매하기` or equivalent actions side by side.
- The final purchase/enrollment action should be the strongest button on the
  page.
- Use deep teal or near-black for the strongest CTA, not both everywhere.
- Update the visible total price immediately when options change.
- Do not require a full page refresh for price recalculation.

## Product Feel

- Calm, credible, and study-oriented.
- Clear enough for students to find lectures quickly.
- Organized enough for progress, enrollment, and lecture state to be obvious.
- Slightly polished, but not decorative.
- Functional before promotional.

## Visual Direction

- Use a light-first interface with strong readability.
- Use `#FFFFFF` as the primary page background so course content stays central.
- Prefer white and cool gray surfaces with subtle blue or green accents.
- Use dark gray text around `#333333` rather than pure black for long reading.
- Use light gray borders around `#E0E0E0` for dividers and metadata grids.
- Use color to indicate learning state:
  blue for primary actions, green for completed progress, amber for in-progress
  or attention states, red only for errors.
- Use deep teal around `#008080` as the main brand/action accent.
- Near-black may be used for a final purchase CTA, but keep it rare.
- Keep borders subtle: `1px` dividers, table lines, and panel boundaries.
- Use soft but restrained elevation only for important surfaces.
- Prefer small radii around `6px` to `8px`.
- Avoid heavy outlines, offset shadows, neon colors, glassmorphism, blurred
  backgrounds, decorative blobs, and gradient-heavy pages.

## Layout

- Build the first screen as a usable course list or dashboard.
- Use a stable app shell:
  top navigation, main content area, and optional right-side progress summary on
  wider screens.
- Keep page sections unframed when possible.
- Use cards for repeated course or lecture items only.
- Do not put cards inside cards.
- Prioritize scanability:
  course title, instructor, lecture count, progress, enrollment action.
- On course detail pages, keep course information and lecture list close
  together.
- On lecture pages, make the simulator and progress state the primary content.

## Component Patterns

- Course cards should be compact and information-rich.
- Lecture lists should look like study checklists:
  sequence, title, duration, progress, completion state.
- Primary actions should be clear text buttons:
  enroll, continue lecture, start lecture.
- Use icon buttons for compact tools only when the icon is familiar.
- Use tabs for major content areas such as curriculum, progress, and course
  information.
- Use badges for completion, enrolled state, and cache/progress debug labels
  only when useful.
- Use progress bars with stable dimensions.
- Keep controls predictable: buttons for commands, toggles for binary settings,
  selects for option sets.

## Typography

- Use readable sans-serif UI typography such as Pretendard or Noto Sans KR.
- Korean copy should be the primary writing source.
- Keep headings compact and clear.
- Make title, section heading, label, and body weights visibly distinct.
- Use hero-scale type only if there is a true hero, which this LMS generally
  should not need.
- Do not scale font size with viewport width.
- Do not use negative letter spacing.
- Use tabular numbers where available for durations, percentages, and progress.

## Content Tone

- Use direct Korean labels.
- Prefer familiar LMS wording:
  `강좌`, `강의`, `수강신청`, `이어보기`, `진도`, `완료`.
- Do not explain UI mechanics inside the page.
- Avoid marketing copy on workflow screens.
- Error messages should tell the user what happened and what to try next.

## Responsive Behavior

- Desktop:
  show course lists and progress summaries side by side when useful; course
  detail pages may use a visual-left, metadata-right two-column layout.
- Narrow desktop:
  preserve lecture list readability and avoid crowded controls.
- Mobile:
  stack content vertically, move the visual area above the metadata grid on
  detail pages, keep primary actions sticky only if it improves the study flow,
  and avoid wide tables.
- At widths below `768px`, convert enrollment detail pages from two columns to
  one vertical column.
- Text must not overflow buttons, badges, cards, list rows, or navigation items.
- Progress bars, simulator controls, and lecture rows should have stable
  dimensions so timer updates do not shift the layout.

## LMS Screen Guidance

### Course List

- Show course title, short description, instructor, lecture count, and progress
  if enrolled.
- Use one clear primary action per course.
- Keep filtering or search simple until real data volume requires more.

### Course Detail

- Place the course summary first.
- Show enrollment state near the title or primary action.
- Use the Structured Enrollment Detail pattern for purchasable or enrollable
  courses.
- Present lectures as a numbered curriculum list.
- Make completed and current lectures visually distinguishable without relying
  on color alone.

### Lecture

- Put the lecture title, duration, simulator, and progress state above secondary
  course metadata.
- Keep Play, Pause, and Reset controls aligned and stable.
- Show progress as both time and percentage.
- Completed state should come from the backend response.

## Validation Checklist

Before considering UI work complete, check:

- Desktop layout around `1440px`.
- Narrow desktop layout around `1024px`.
- Mobile layout around `390px`.
- Long Korean course and lecture names.
- Course cards with and without enrollment.
- Lecture progress at `0%`, partial, `90%`, and complete.
- Button and badge text overflow.
- Simulator timer updates without layout shift.
