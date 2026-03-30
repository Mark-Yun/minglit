/**
 * Lightweight JSON Schema (Draft 2020-12 subset) validator for contract tests.
 *
 * Supports: type, required, properties, additionalProperties, const, enum,
 * minLength, items, oneOf, and nested objects/arrays.
 */

type Schema = Record<string, unknown>;

interface ValidationError {
  path: string;
  message: string;
}

export function validateSchema(
  data: unknown,
  schema: Schema,
  path = "$",
): ValidationError[] {
  const errors: ValidationError[] = [];

  // const
  if ("const" in schema) {
    if (data !== schema.const) {
      errors.push({ path, message: `expected const ${JSON.stringify(schema.const)}, got ${JSON.stringify(data)}` });
    }
  }

  // enum
  if ("enum" in schema && Array.isArray(schema.enum)) {
    if (!schema.enum.includes(data)) {
      errors.push({ path, message: `expected one of [${schema.enum.join(", ")}], got ${JSON.stringify(data)}` });
    }
  }

  // type
  if ("type" in schema) {
    const expectedType = schema.type as string;
    if (!matchesType(data, expectedType)) {
      errors.push({ path, message: `expected type "${expectedType}", got ${typeof data}` });
      return errors; // skip further checks if type doesn't match
    }
  }

  // minLength (string)
  if ("minLength" in schema && typeof data === "string") {
    if (data.length < (schema.minLength as number)) {
      errors.push({ path, message: `string length ${data.length} < minLength ${schema.minLength}` });
    }
  }

  // object checks
  if (typeof data === "object" && data !== null && !Array.isArray(data)) {
    const obj = data as Record<string, unknown>;

    // required
    if ("required" in schema && Array.isArray(schema.required)) {
      for (const key of schema.required) {
        if (!(key in obj)) {
          errors.push({ path: `${path}.${key}`, message: `missing required property "${key}"` });
        }
      }
    }

    // properties
    if ("properties" in schema && typeof schema.properties === "object") {
      const props = schema.properties as Record<string, Schema>;
      for (const [key, propSchema] of Object.entries(props)) {
        if (key in obj) {
          errors.push(...validateSchema(obj[key], propSchema, `${path}.${key}`));
        }
      }
    }

    // additionalProperties
    if ("additionalProperties" in schema && schema.additionalProperties === false) {
      const allowedKeys = new Set(
        Object.keys((schema.properties ?? {}) as Record<string, unknown>),
      );
      for (const key of Object.keys(obj)) {
        if (!allowedKeys.has(key)) {
          errors.push({ path: `${path}.${key}`, message: `unexpected additional property "${key}"` });
        }
      }
    }
  }

  // array items
  if (Array.isArray(data) && "items" in schema && typeof schema.items === "object") {
    const itemSchema = schema.items as Schema;
    for (let i = 0; i < data.length; i++) {
      errors.push(...validateSchema(data[i], itemSchema, `${path}[${i}]`));
    }
  }

  // oneOf
  if ("oneOf" in schema && Array.isArray(schema.oneOf)) {
    const matchCount = schema.oneOf.filter(
      (sub: unknown) => validateSchema(data, sub as Schema, path).length === 0,
    ).length;
    if (matchCount === 0) {
      errors.push({ path, message: "does not match any oneOf schema" });
    }
  }

  return errors;
}

function matchesType(data: unknown, expectedType: string): boolean {
  switch (expectedType) {
    case "string":
      return typeof data === "string";
    case "number":
    case "integer":
      return typeof data === "number";
    case "boolean":
      return typeof data === "boolean";
    case "object":
      return typeof data === "object" && data !== null && !Array.isArray(data);
    case "array":
      return Array.isArray(data);
    case "null":
      return data === null;
    default:
      return true;
  }
}

/** Validates data against a schema and throws on failure. */
export function assertMatchesSchema(
  data: unknown,
  schema: Schema,
  label = "data",
): void {
  const errors = validateSchema(data, schema);
  if (errors.length > 0) {
    const details = errors.map((e) => `  ${e.path}: ${e.message}`).join("\n");
    throw new Error(`${label} does not match schema:\n${details}`);
  }
}
