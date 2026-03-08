export const config = { runtime: 'edge' };

const APP_URL = 'https://app.minglit.com';
const FALLBACK_IMAGE = `${APP_URL}/icons/Icon-512.png`;
const FALLBACK_TITLE = 'Minglit — 소셜 이벤트 매칭';
const FALLBACK_DESCRIPTION = '밍글잇에서 다양한 소셜 이벤트를 만나보세요.';

interface EventRow {
  title?: string | null;
  description?: { ops?: Array<{ insert: string | object }> } | null;
  image_urls?: string[] | null;
}

function quillDeltaToText(description: EventRow['description']): string {
  const ops = description?.ops ?? [];
  return ops
    .filter((op): op is { insert: string } => typeof op.insert === 'string')
    .map((op) => op.insert.replace(/\n/g, ' ').trim())
    .join(' ')
    .trim()
    .substring(0, 150);
}

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function buildHtml(params: {
  title: string;
  description: string;
  image: string;
  url: string;
}): string {
  const { title, description, image, url } = params;
  const t = escapeHtml(title);
  const d = escapeHtml(description);
  const i = escapeHtml(image);
  const u = escapeHtml(url);

  return `<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${t}</title>
  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="Minglit" />
  <meta property="og:title" content="${t}" />
  <meta property="og:description" content="${d}" />
  <meta property="og:image" content="${i}" />
  <meta property="og:url" content="${u}" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${t}" />
  <meta name="twitter:description" content="${d}" />
  <meta name="twitter:image" content="${i}" />
</head>
<body>
  <script>
    window.location.replace("${u}");
  </script>
</body>
</html>`;
}

function fallbackHtml(eventId: string): string {
  return buildHtml({
    title: FALLBACK_TITLE,
    description: FALLBACK_DESCRIPTION,
    image: FALLBACK_IMAGE,
    url: eventId
      ? `${APP_URL}/events/${eventId}`
      : APP_URL,
  });
}

function htmlResponse(html: string): Response {
  return new Response(html, {
    status: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'public, max-age=60, stale-while-revalidate=300',
    },
  });
}

export default async function handler(request: Request): Promise<Response> {
  const { searchParams } = new URL(request.url);
  const eventId = searchParams.get('eventId');

  if (!eventId) {
    return htmlResponse(fallbackHtml(''));
  }

  try {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_ANON_KEY;

    if (!supabaseUrl || !supabaseKey) {
      return htmlResponse(fallbackHtml(eventId));
    }

    const apiUrl =
      `${supabaseUrl}/rest/v1/events` +
      `?id=eq.${encodeURIComponent(eventId)}` +
      `&select=title,description,image_urls`;

    const res = await fetch(apiUrl, {
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
        Accept: 'application/json',
      },
    });

    if (!res.ok) {
      return htmlResponse(fallbackHtml(eventId));
    }

    const data = (await res.json()) as EventRow[];

    if (!data || data.length === 0) {
      return htmlResponse(fallbackHtml(eventId));
    }

    const event = data[0];

    const title = event.title?.trim() || FALLBACK_TITLE;
    const description =
      quillDeltaToText(event.description) || FALLBACK_DESCRIPTION;
    const image =
      (event.image_urls && event.image_urls[0]) || FALLBACK_IMAGE;
    const url = `${APP_URL}/events/${eventId}`;

    return htmlResponse(buildHtml({ title, description, image, url }));
  } catch {
    return htmlResponse(fallbackHtml(eventId));
  }
}
