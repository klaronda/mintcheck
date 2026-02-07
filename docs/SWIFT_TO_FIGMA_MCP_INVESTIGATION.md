# Swift Screens → Figma via MCP: Investigation

## Goal

Take coded Swift (SwiftUI) screens and create equivalent designs in Figma so you have access to all components in Figma (design system, handoff, iteration).

## Current Setup vs TalkToFigma

| | **Figma Desktop** (current) | **TalkToFigma** (grab/cursor-talk-to-figma-mcp) |
|---|---|---|
| **Direction** | One-way: Figma → Cursor | Two-way: Cursor ↔ Figma |
| **Tools** | `get_design_context`, `get_metadata`, `get_screenshot`, `get_figjam`, `get_variable_defs`, `create_design_system_rules` | Read: `get_document_info`, `get_selection`, `get_node_info`, etc. **Write: `create_frame`, `create_text`, `create_rectangle`, `set_fill_color`, `set_layout_mode`, etc.** |
| **Use** | Generate code from Figma selection | Read designs **and** create/modify designs from Cursor |

Your current **Figma Desktop** MCP is read-only (design → code). To create screens **in** Figma from code, you need **write** capability. The [grab/cursor-talk-to-figma-mcp](https://github.com/grab/cursor-talk-to-figma-mcp) server provides that.

## TalkToFigma: What You Need

1. **Bun** (runtime for the MCP server)
2. **TalkToFigma MCP** in Cursor (`~/.cursor/mcp.json`)
3. **WebSocket server** running: `bun socket` (from the repo or after `bunx cursor-talk-to-figma-mcp@latest` you run the socket from the package)
4. **Figma plugin** running in Figma: “Cursor MCP Plugin” from [Figma Community](https://www.figma.com/community/plugin/1485687494525374295/cursor-talk-to-figma-mcp-plugin)
5. **Channel**: In Cursor, call `join_channel` (e.g. a shared channel name) so the MCP and the Figma plugin talk to the same session

Creation tools you’ll use for Swift → Figma:

- **Frames & layout**: `create_frame`, `create_rectangle` (containers, cards)
- **Text**: `create_text` (labels, titles, body)
- **Auto layout**: `set_layout_mode` (HORIZONTAL / VERTICAL), `set_padding`, `set_item_spacing`, `set_axis_align`
- **Styling**: `set_fill_color`, `set_stroke_color`, `set_corner_radius`
- **Structure**: `move_node`, `resize_node`, `clone_node`

So you can keep **Figma Desktop** for “Figma → code” and add **TalkToFigma** for “code → Figma”.

## Swift UI → Figma: Two Approaches

### 1. Cursor + TalkToFigma (no custom code)

- Add TalkToFigma to Cursor and open your Swift screen (e.g. `SignInView.swift`, `DashboardView.swift`).
- In chat, ask Cursor to “create this screen in Figma” and point to the file (or paste the view body).
- Cursor uses TalkToFigma tools to create frames, text, and rectangles that mirror the layout (VStack/HStack → auto-layout frames, Text → `create_text`, spacing/padding → `set_item_spacing` / `set_padding`).
- You refine in Figma and can later use Figma Desktop to pull design context back into code if needed.

Best for: per-screen, iterative “recreate this Swift screen in Figma” with minimal tooling.

### 2. Swift UI → Figma bridge (translator)

- **Input**: SwiftUI view code (or a structured representation: view hierarchy, frames, text, colors, spacing).
- **Mapping** (conceptual):
  - `VStack` → frame with `set_layout_mode` VERTICAL, `set_item_spacing`
  - `HStack` → frame with `set_layout_mode` HORIZONTAL
  - `Text("...")` + `.font()` → `create_text` with font/size
  - `Color` / `RoundedRectangle` / `.background()` → `create_rectangle` + `set_fill_color`, `set_corner_radius`
  - `.padding()` → `set_padding`
  - Your design system (`LayoutConstants`, `FontSize`, `Colors`) → same constants in Figma (colors, radii, spacing)
- **Output**: A sequence of MCP calls (or a script that invokes the MCP) to create one Figma frame per screen and nested nodes for each component.

Challenges:

- SwiftUI layout is dynamic; Figma uses explicit frames or auto-layout. You’ll need conventions (e.g. one root frame per screen, fixed width like 390pt).
- Custom views (`ScreenHeader`, `InputField`, `PrimaryButton`) must be expanded into primitives (frames + text + rectangles) or mapped to Figma components you create once.
- Fonts: map `.system(size:weight:)` to Figma font/size; may need a small mapping table.

Practical path: start with **approach 1** (Cursor + TalkToFigma) for a few screens (e.g. Sign In, Dashboard). If you need to automate many screens, add a small **bridge** that:

- Parses or describes Swift UI structure (e.g. simple JSON/YAML or AST-based), then
- Generates a “spec” (list of frames, text, colors, spacing) that Cursor or a script turns into TalkToFigma MCP calls.

### MintCheck design tokens (for Figma parity)

Use these when creating screens in Figma so they match your app. TalkToFigma uses **RGBA 0–1** for colors; hex below is for reference.

| Swift | Value | Figma / MCP |
|-------|--------|-------------|
| **Colors** | | |
| `.mintGreen` | #3EB489 | r 0.24, g 0.71, b 0.54, a 1 |
| `.textPrimary` | #1A1A1A | r 0.1, g 0.1, b 0.1, a 1 |
| `.textSecondary` | #666666 | r 0.4, g 0.4, b 0.4, a 1 |
| `.borderColor` | #E5E5E5 | r 0.9, g 0.9, b 0.9, a 1 |
| `.deepBackground` | #F8F8F7 | r 0.97, g 0.97, b 0.97, a 1 |
| **Layout** | | |
| `LayoutConstants.borderRadius` | 4 | `set_corner_radius` 4 |
| `LayoutConstants.borderRadiusLarge` | 8 | `set_corner_radius` 8 |
| `LayoutConstants.padding6` | 24 | `set_padding` 24 (or 24,24,24,24) |
| `LayoutConstants.spacing*` | 4, 8, 16, 24 | `set_item_spacing` |
| **Typography** | | |
| `FontSize.h1` | 26 | create_text fontSize 26, semibold |
| `FontSize.h4` | 17 | create_text fontSize 17, semibold |
| `FontSize.bodyLarge` | 15 | create_text fontSize 15 |
| **Screen** | | |
| Mobile width | 390 pt | create_frame width 390 (e.g. Sign In, Dashboard) |

## Setup (TalkToFigma)

**Already done:** TalkToFigma is added to your `~/.cursor/mcp.json`:

```json
"TalkToFigma": {
  "command": "bunx",
  "args": ["cursor-talk-to-figma-mcp@latest"]
}
```

**You need to do:**

1. **Install Bun** (if you don’t have it):
   ```bash
   curl -fsSL https://bun.sh/install | bash
   ```

2. **Run the WebSocket server** (required for Cursor ↔ Figma plugin). Either:
   - **Option A – from the repo (recommended):**
     ```bash
     git clone https://github.com/grab/cursor-talk-to-figma-mcp.git
     cd cursor-talk-to-figma-mcp
     bun install
     bun socket
     ```
     Leave this terminal open while using TalkToFigma.
   - **Option B – from a project where you’ve linked the package:** if you ran `bun setup` from the repo in a project, you can run `bun socket` from that repo directory.

3. **Figma plugin:** Install [Cursor MCP Plugin](https://www.figma.com/community/plugin/1485687494525374295/cursor-talk-to-figma-mcp-plugin) in Figma, then run it and **join a channel** (e.g. `mintcheck`). The plugin must be running and connected for Cursor to talk to Figma.

4. **Connect in Cursor:** In a Cursor chat, call the `join_channel` tool with the **same channel name** (e.g. `mintcheck`). After that, other TalkToFigma tools will target that Figma file.

5. **Restart Cursor** (or reload MCP) so it picks up the new TalkToFigma server.

## Next Steps

1. Start the WebSocket server and the Figma plugin, then `join_channel` in Cursor.
2. Open a Swift screen (e.g. `SignInView.swift` or `DashboardView.swift`) and ask Cursor to create that screen in Figma using TalkToFigma tools.
3. Refine the result in Figma and reuse components as needed.

If you need to automate many screens later, consider the Swift → Figma bridge (approach 2) and a spec-driven flow.
