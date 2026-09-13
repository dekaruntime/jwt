function object_json(json) {
  const value = JSON.parse(json);
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("expected a JWT object");
  }
  return value;
}
export function parse_header_json(json) {
  const header = object_json(json);
  if (header.alg != null && typeof header.alg !== "string") throw new Error("invalid JWT alg");
  return header;
}
export function parse_claims_json(json) {
  const claims = object_json(json);
  for (const key of ["iat", "exp", "nbf"]) {
    if (claims[key] != null && (typeof claims[key] !== "number" || !Number.isFinite(claims[key]))) {
      throw new Error("invalid JWT numeric claim");
    }
  }
  for (const key of ["iss", "aud", "sub"]) {
    if (claims[key] != null && typeof claims[key] !== "string") throw new Error("invalid JWT string claim");
  }
  return claims;
}
// Preserve custom payload fields and insertion order (including existing vectors).
// Optional parameters cross the summon Option seam as undefined when absent.
export function serialize_claims(payload, iat, exp, iss, aud, sub) {
  const claims = Object.assign({}, payload);
  if (iss != null) claims.iss = iss;
  if (aud != null) claims.aud = aud;
  if (sub != null) claims.sub = sub;
  claims.iat = iat;
  if (exp != null) claims.exp = exp;
  return JSON.stringify(claims);
}
export function now_seconds() { return Math.floor(Date.now() / 1000); }
export function valid_b64url(value) { return /^[A-Za-z0-9_-]+$/.test(value) && value.length % 4 !== 1; }
