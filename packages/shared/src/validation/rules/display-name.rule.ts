import { validateStringValues } from "../rule.utils";
import { ValidationRule } from "../validation-rule.interface";

const DISPLAY_NAME_PART_PATTERN = "[\\p{L}\\p{M}]+(?:['-][\\p{L}\\p{M}]+)*";
const DISPLAY_NAME_REGEX = new RegExp(
  `^\\s*${DISPLAY_NAME_PART_PATTERN}(?:\\s+${DISPLAY_NAME_PART_PATTERN})*\\s*$`,
  "u",
);

export class DisplayNameRule implements ValidationRule {
  validate(value: unknown): string | null {
    return validateStringValues(value, "display.name", (item) =>
      DISPLAY_NAME_REGEX.test(item),
    );
  }
}
