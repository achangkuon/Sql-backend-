# Design System Document: The Service Editorial

## 1. Overview & Creative North Star
**Creative North Star: "The Architectural Assistant"**
This design system moves away from the generic "utility app" aesthetic to embrace a high-end editorial feel. We are not just building a task manager; we are designing a workspace for professionals. By blending the geometric, avant-garde nature of **Syne** with the utilitarian precision of **DM Sans**, we create a "Soft Minimalist" environment. 

The system breaks the standard "template" look through **intentional asymmetry** and **tonal layering**. We prioritize white space as a functional tool, using it to group elements rather than relying on rigid lines. The interface should feel like a series of premium, stacked cards—physical, tactile, and highly organized.

---

## 2. Colors & Surface Philosophy

### Color Palette (Material Token Mapping)
*   **Primary:** `#1A6BFF` (Action & Brand Authority)
*   **Surface / Background:** `#F7F8FA` 
*   **Surface Container (Lowest):** `#FFFFFF` (Card Backgrounds)
*   **Surface Container (Low):** `#EFF1F5` (Secondary Backgrounds / Sectioning)
*   **Surface Variant (Chips):** `#E8F0FF` (Informational accents)
*   **Urgent (Tertiary):** `#FF5C3A`
*   **Success:** `#22C55E`
*   **Warning:** `#F59E0B`
*   **Text Primary:** `#0D0F1A`
*   **Text Secondary:** `#6B7280`

### The "No-Line" Rule
**Standard 1px borders are strictly prohibited for sectioning.** To define boundaries, designers must use background color shifts. A `surface-container-lowest` (#FFFFFF) card must sit on a `surface` (#F7F8FA) background to create definition. 

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers.
1.  **Base:** `surface` (#F7F8FA)
2.  **Sectioning:** `surface-container-low` (#EFF1F5)
3.  **Interaction Layer:** `surface-container-lowest` (#FFFFFF)

### The "Glass & Gradient" Rule
To add "soul" to the primary actions, use a subtle linear gradient on primary buttons: `linear-gradient(135deg, #1A6BFF 0%, #0053D3 100%)`. For floating action buttons or navigation overlays, utilize **Glassmorphism**: a background blur of `20px` combined with a 70% opacity version of the surface color.

---

## 3. Typography: Editorial Authority

The typographic rhythm is the backbone of this system. We use a high-contrast scale to ensure a "premium" feel.

*   **Display & Headlines (Syne - Bold/Extrabold):** Used for titles, numbers, and high-impact headers. Syne’s wide letterforms provide an architectural, modern strength.
    *   *Headline-LG:* 2rem / Syne Bold
    *   *Headline-MD:* 1.75rem / Syne Bold
*   **Titles & Body (DM Sans - Regular/Medium):** DM Sans provides the necessary legibility for dense service data.
    *   *Title-MD:* 1.125rem / DM Sans Medium
    *   *Body-LG:* 1rem / DM Sans Regular
    *   *Label-MD:* 0.75rem / DM Sans Medium (All-caps for category labels)

**Note on Spanish (Latinoamericano):** Ensure line heights are generous (1.5x) to accommodate longer word lengths common in Spanish without causing visual density issues.

---

## 4. Elevation & Depth: Tonal Layering

We avoid "floating" elements with heavy shadows. Instead, we use **Tonal Layering**.

*   **The Layering Principle:** Depth is achieved by stacking. Place a white card on the light grey background. The contrast itself provides the "lift."
*   **Ambient Shadows:** When a card requires a floating effect (e.g., a "Task in Progress" card), use a shadow: `0px 10px 30px rgba(13, 15, 26, 0.04)`. The shadow is nearly invisible, mimicking natural, soft ambient light.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility in input fields, use `#E5E7EB` at 40% opacity. Never use 100% opaque borders.

---

## 5. Components

### Buttons & Chips
*   **Primary Button:** 14px border-radius, Syne Bold text, subtle gradient.
*   **Secondary Button:** Surface-container-low background (#EFF1F5), no border, DM Sans Medium text.
*   **Chips (Pill-shaped):** 999px border-radius. Use `surface-variant` (#E8F0FF) for general info and `Tertiary-Container` for urgent statuses.

### Input Fields
*   **The Floating Label:** Use DM Sans Medium for labels. Input fields should have a 14px radius and use the `surface-container-lowest` (#FFFFFF) fill. When focused, use a 1.5px primary color "Ghost Border" (at 20% opacity).

### Cards & Lists
*   **Forbid Dividers:** Never use a horizontal line to separate list items. Use **8px to 12px of vertical white space** or a subtle background shift to `surface-container-low` on every second item to create a zebra-stripe effect for readability.
*   **Nesting:** Service details (price, time) should be placed in a `surface-variant` (#E8F0FF) pill within the card to separate them from the task description.

### Specialized Component: The "Urgency Banner"
For high-priority tasks, use the **Urgent color (#FF5C3A)** as a 4px left-hand accent bar on a white card. Do not color the whole card; the accent bar conveys "Editorial Importance" without overwhelming the user.

---

## 6. Do’s and Don’ts

### Do:
*   **Use Asymmetry:** Place high-impact numbers (prices, dates) in the top right using Syne Extrabold to create a dynamic visual path.
*   **Embrace White Space:** If a screen feels "empty," it’s likely working. Let the professional's data breathe.
*   **Use Localized Phrasing:** Use "Aceptar Tarea" or "Tareas Pendientes" instead of generic English-translated terms.

### Don’t:
*   **Don't Use 1px Borders:** It breaks the "Architectural" feel and makes the app look like a generic framework.
*   **Don't Over-Shadow:** If you can see the shadow clearly, it’s too dark. 
*   **Don't Mix Fonts:** Never use Syne for body paragraphs; its width makes long-form reading difficult. Keep it for headers and "data-points" (numbers).