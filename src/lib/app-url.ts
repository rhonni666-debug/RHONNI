export function appUrl(path = "") {
  const base = import.meta.env.BASE_URL.endsWith("/")
    ? import.meta.env.BASE_URL
    : `${import.meta.env.BASE_URL}/`;
  const cleanPath = path.replace(/^\/+/, "");
  return new URL(cleanPath, new URL(base, window.location.origin)).toString();
}
