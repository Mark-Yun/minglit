/// Returns a transformed Supabase Storage URL with width/quality query params,
/// or the original URL if it isn't a Supabase Storage URL.
///
/// When [width] is provided and the URL is a Supabase public-object URL
/// (`/storage/v1/object/public/`), the URL is rewritten to the render/image
/// transform endpoint (`/storage/v1/render/image/public/`) so the CDN resizes
/// the image server-side before delivery. This reduces both network payload
/// and Flutter's in-memory decode cost.
///
/// Already-transformed render URLs (`/storage/v1/render/image/`) have
/// `width` and `quality` merged into their existing query string.
///
/// Non-Supabase URLs are returned unchanged.
String supabaseImageUrl(String url, {int? width, int quality = 70}) {
  if (url.isEmpty) return url;

  const objectPath = '/storage/v1/object/public/';
  const renderPath = '/storage/v1/render/image/public/';
  const renderCheck = '/storage/v1/render/image/';

  final isObjectUrl = url.contains(objectPath);
  final isRenderUrl = url.contains(renderCheck);

  if (!isObjectUrl && !isRenderUrl) {
    // Not a Supabase Storage URL — return as-is.
    return url;
  }

  // Fix #1918: render path requires Image Transformations to be enabled in
  // Supabase settings; skip the rewrite entirely when no transform is needed.
  if (width == null) {
    return url;
  }

  // Rewrite public-object URLs to the render/image transform endpoint.
  final base = isObjectUrl ? url.replaceFirst(objectPath, renderPath) : url;

  // Merge width + quality into the existing query string.
  final uri = Uri.parse(base);
  final params = Map<String, String>.from(uri.queryParameters)
    ..['width'] = width.toString()
    ..['quality'] = quality.toString();

  return uri.replace(queryParameters: params).toString();
}
