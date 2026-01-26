// Badge and freshness logic for shared reports (see SHARED_REPORTS_HANDOFF.md)

export type FreshnessStatus = 'Current' | 'Expires Soon' | 'Expired';

export function getScanFreshness(scanDate: string): {
  status: FreshnessStatus;
  daysOld: number;
  validUntil: Date;
  validUntilFormatted: string;
  expiresOnFormatted: string;
} {
  const scan = new Date(scanDate);
  const now = new Date();
  const diffTime = now.getTime() - scan.getTime();
  const daysOld = Math.floor(diffTime / (1000 * 60 * 60 * 24));

  const validUntil = new Date(scan);
  validUntil.setDate(validUntil.getDate() + 14);

  let status: FreshnessStatus;
  if (daysOld <= 10) {
    status = 'Current';
  } else if (daysOld <= 14) {
    status = 'Expires Soon';
  } else {
    status = 'Expired';
  }

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

export function formatReportDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

export function formatReportDateLong(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });
}

export function getRecommendationStyle(recommendation: 'safe' | 'caution' | 'not-recommended'): {
  bg: string;
  border: string;
  text: string;
  badge: string;
  headline: string;
} {
  switch (recommendation) {
    case 'safe':
      return {
        bg: '#E6F4EE',
        border: '#3EB489',
        text: '#2D7A5E',
        badge: 'Healthy',
        headline: 'Car is Healthy',
      };
    case 'caution':
      return {
        bg: '#FFF9E6',
        border: '#E3B341',
        text: '#9A7B2C',
        badge: 'Caution',
        headline: 'Proceed with Caution',
      };
    case 'not-recommended':
      return {
        bg: '#FFE6E6',
        border: '#C94A4A',
        text: '#9A3A3A',
        badge: 'Walk Away',
        headline: 'Walk Away',
      };
    default:
      return {
        bg: '#F0F0F0',
        border: '#999999',
        text: '#666666',
        badge: 'Unknown',
        headline: 'Unknown',
      };
  }
}

export function getFreshnessBadgeStyle(status: FreshnessStatus): { bg: string; text: string } {
  switch (status) {
    case 'Current':
      return { bg: '#E6F4EE', text: '#2D7A5E' };
    case 'Expires Soon':
      return { bg: '#FFF8E6', text: '#9A7B2C' };
    case 'Expired':
      return { bg: '#FFE6E6', text: '#9A3A3A' };
    default:
      return { bg: '#F0F0F0', text: '#666666' };
  }
}
