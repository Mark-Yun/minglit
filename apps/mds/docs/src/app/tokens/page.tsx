import {
  getColorTokens,
  getSpacingTokens,
  getRadiusTokens,
  getTypographyTokens,
} from '@/lib/tokens';
import TokensPageClient from './TokensPageClient';

/**
 * Server component — reads token JSON files at build time and hands the
 * data to the client tab UI.
 */
export default function TokensPage() {
  return (
    <TokensPageClient
      colors={getColorTokens()}
      spacing={getSpacingTokens()}
      radii={getRadiusTokens()}
      typography={getTypographyTokens()}
    />
  );
}
