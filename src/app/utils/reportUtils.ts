export type FreshnessStatus = 'Current' | 'Expires Soon' | 'Expired';

export function getScanFreshness(scanDate: string): {
  status: FreshnessStatus;
  daysOld: number;
  validUntil: Date;
  validUntilFormatted: string;
  expiresOnFormatted: string;
} {
  const scan = new Date(scanDate);
  const now = Date.now();
  const daysOld = Math.floor((now - scan.getTime()) / (1000 * 60 * 60 * 24));
  const validUntil = new Date(scan);
  validUntil.setDate(validUntil.getDate() + 14);

  let status: FreshnessStatus;
  if (daysOld <= 10) status = 'Current';
  else if (daysOld <= 14) status = 'Expires Soon';
  else status = 'Expired';

  return {
    status,
    daysOld,
    validUntil,
    validUntilFormatted: validUntil.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    }),
    expiresOnFormatted: validUntil.toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    }),
  };
}

export function formatReportDateLong(scanDate: string): string {
  return new Date(scanDate).toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });
}

const RECO_STYLES = {
  safe: {
    bg: '#E6F4EE',
    border: '#3EB489',
    text: '#2D7A5E',
    badge: 'Healthy',
    headline: 'Car is Healthy',
  },
  caution: {
    bg: '#FFF9E6',
    border: '#E3B341',
    text: '#9A7B2C',
    badge: 'Caution',
    headline: 'Proceed with Caution',
  },
  'not-recommended': {
    bg: '#FFE6E6',
    border: '#C94A4A',
    text: '#9A3A3A',
    badge: 'Walk Away',
    headline: 'Walk Away',
  },
} as const;

export function getRecommendationStyle(recommendation: 'safe' | 'caution' | 'not-recommended') {
  return RECO_STYLES[recommendation];
}

const FRESHNESS_BADGE_STYLES: Record<FreshnessStatus, { bg: string; text: string }> = {
  'Current': { bg: '#E6F4EE', text: '#2D7A5E' },
  'Expires Soon': { bg: '#FFF8E6', text: '#9A7B2C' },
  'Expired': { bg: '#FFE6E6', text: '#9A3A3A' },
};

export function getFreshnessBadgeStyle(status: FreshnessStatus): { bg: string; text: string } {
  return FRESHNESS_BADGE_STYLES[status];
}
