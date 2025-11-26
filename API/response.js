// puzzle-loader.js
import { create_target } from "./target.js"; // see Step 2

const params = new URLSearchParams(window.location.search);
const date = parseInt(params.get("date"));
if (!isNaN(date)) {
    const output = create_target(date);
    document.body.textContent = output; // pure text response
} else {
    document.body.textContent = "Invalid date parameter";
}
