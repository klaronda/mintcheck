import { AlertTriangle, Check, Info, User, Wrench } from 'lucide-react';

interface VehicleHistoryReportProps {
  carfaxData: { vhr: unknown };
}

function safeStr(val: unknown): string {
  if (val == null) return '';
  if (typeof val === 'string') return val;
  return String(val);
}

/** Replace CARFAX with MintCheck in report-sourced text; header subtext is the only place we keep "CARFAX". */
function toMintCheckText(s: string): string {
  return s.replace(/CARFAX/gi, 'MintCheck');
}

export function VehicleHistoryReport({ carfaxData }: VehicleHistoryReportProps) {
  const vhr = carfaxData?.vhr as Record<string, unknown> | null | undefined;
  if (!vhr || typeof vhr !== 'object') return null;

  const headerSection = vhr.headerSection as Record<string, unknown> | undefined;
  const vehicleInfo = headerSection?.vehicleInformationSection as Record<string, unknown> | undefined;
  if (!vehicleInfo) return null;

  const historyOverview = (headerSection?.historyOverview as { rows?: unknown[] })?.rows ?? [];
  const titleHistory = ((vhr.titleHistorySection as { rows?: unknown[] })?.rows ?? []) as Record<string, unknown>[];
  const additionalHistory = ((vhr.additionalHistorySection as { rows?: unknown[] })?.rows ?? []) as Record<string, unknown>[];
  const ownershipHistory = ((vhr.ownershipHistorySection as { rows?: unknown[] })?.rows ?? []) as Record<string, unknown>[];
  const detailsSection = ((vhr.detailsSection as { ownerBlocks?: { ownerBlocks?: unknown[] } })?.ownerBlocks?.ownerBlocks ?? []) as Record<string, unknown>[];
  const accidentDamage = ((vhr.accidentDamageSection as { accidentDamageRecords?: unknown[] })?.accidentDamageRecords ?? []) as Record<string, unknown>[];

  const lastOdometer = historyOverview.find((r: { name?: string }) => r.name === 'lastOdoReported') as { text?: string } | undefined;
  const ownerCount = historyOverview.find((r: { name?: string }) => r.name === 'ownershipCount') as { text?: string } | undefined;
  const ownershipType = historyOverview.find((r: { name?: string }) => r.name === 'ownershipType') as { text?: string } | undefined;
  const lastState = historyOverview.find((r: { name?: string }) => r.name === 'stateRegistered') as { text?: string } | undefined;
  const serviceCount = historyOverview.find((r: { name?: string }) => r.name === 'service') as { text?: string } | undefined;
  const hasBrandedTitle = historyOverview.find((r: { name?: string }) => r.name === 'damageBrandedTitle');

  // Recommendation: show caution text if branded title (Junk/Rebuilt/Salvage) OR any accident/damage; else "History Available"
  const hasAlert = !!hasBrandedTitle || accidentDamage.length > 0;
  const statusColor = hasAlert ? '#C94A4A' : '#3EB489';
  const statusBg = hasAlert ? '#FFE6E6' : '#E6F4EE';
  const statusText = hasAlert ? 'Problems Reported' : 'History Available';

  const numOwnerColumns = (ownershipHistory[0] as { cells?: unknown[] })?.cells?.length ?? 0;

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#F8F8F7', padding: '20px' }}>
      <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
        {/* Header */}
        <div style={{
          backgroundColor: '#3EB489',
          padding: '32px',
          borderRadius: '4px 4px 0 0',
          marginBottom: '0',
        }}>
          <h1 style={{ fontSize: '28px', fontWeight: 600, color: '#FFFFFF', marginBottom: '8px' }}>
            MintCheck
          </h1>
          <p style={{ fontSize: '15px', color: '#FFFFFF', opacity: 0.9, margin: 0 }}>
            Vehicle History Report via CARFAX
          </p>
        </div>

        {/* Main Report Card */}
        <div style={{
          backgroundColor: '#FFFFFF',
          border: '1px solid #E5E5E5',
          borderRadius: '0 0 4px 4px',
          padding: '32px',
          marginBottom: '24px',
        }}>
          <div style={{ marginBottom: '32px' }}>
            <h2 style={{ fontSize: '24px', fontWeight: 600, color: '#1A1A1A', marginBottom: '8px' }}>
              {toMintCheckText(safeStr(vehicleInfo.yearMakeModel))}
            </h2>
            <p style={{ fontSize: '14px', color: '#666666', fontFamily: 'monospace', margin: 0 }}>
              VIN: {toMintCheckText(safeStr(vehicleInfo.vin))}
            </p>
          </div>

          <div style={{
            backgroundColor: statusBg,
            border: `2px solid ${statusColor}`,
            borderRadius: '4px',
            padding: '16px 20px',
            marginBottom: '32px',
            textAlign: 'center',
          }}>
            <span style={{ fontSize: '17px', fontWeight: 600, color: statusColor }}>
              {statusText}
            </span>
          </div>

          <div style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
            gap: '16px',
            marginBottom: '32px',
          }}>
            {lastOdometer && (
              <div style={{ backgroundColor: '#F8F8F7', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '16px' }}>
                <div style={{ fontSize: '13px', color: '#666666', marginBottom: '4px' }}>Last Reported Odometer</div>
                <div style={{ fontSize: '20px', fontWeight: 600, color: '#1A1A1A' }}>
                  {toMintCheckText(safeStr(lastOdometer.text)).replace(/<\/?strong>/g, '').replace(' Last reported odometer reading', '')}
                </div>
              </div>
            )}
            {ownerCount && (
              <div style={{ backgroundColor: '#F8F8F7', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '16px' }}>
                <div style={{ fontSize: '13px', color: '#666666', marginBottom: '4px' }}>Previous Owners</div>
                <div style={{ fontSize: '20px', fontWeight: 600, color: '#1A1A1A' }}>
                  {toMintCheckText(safeStr(ownerCount.text)).replace(/<\/?strong>/g, '').replace(' Previous owners', '')}
                </div>
              </div>
            )}
            {ownershipType && (
              <div style={{ backgroundColor: '#F8F8F7', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '16px' }}>
                <div style={{ fontSize: '13px', color: '#666666', marginBottom: '4px' }}>Vehicle Type</div>
                <div style={{ fontSize: '20px', fontWeight: 600, color: '#1A1A1A' }}>{toMintCheckText(safeStr(ownershipType.text))}</div>
              </div>
            )}
            {lastState && (
              <div style={{ backgroundColor: '#F8F8F7', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '16px' }}>
                <div style={{ fontSize: '13px', color: '#666666', marginBottom: '4px' }}>Last Location</div>
                <div style={{ fontSize: '20px', fontWeight: 600, color: '#1A1A1A' }}>
                  {toMintCheckText(safeStr(lastState.text)).replace('Last owned in ', '')}
                </div>
              </div>
            )}
            {serviceCount && (
              <div style={{ backgroundColor: '#F8F8F7', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '16px' }}>
                <div style={{ fontSize: '13px', color: '#666666', marginBottom: '4px' }}>Service Records</div>
                <div style={{ fontSize: '20px', fontWeight: 600, color: '#1A1A1A' }}>
                  {toMintCheckText(safeStr(serviceCount.text)).replace(/<\/?strong>/g, '').replace(' Service history records', '')}
                </div>
              </div>
            )}
          </div>

          <div style={{ backgroundColor: '#FCFCFB', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '16px', marginBottom: '32px' }}>
            <p style={{ fontSize: '14px', color: '#666666', lineHeight: 1.6, margin: 0 }}>
              <strong style={{ color: '#1A1A1A' }}>Note:</strong> This report is based on information available as of {new Date().toLocaleDateString()}. Not all accidents or issues may be reported. Use this report along with a vehicle inspection and test drive to make an informed decision.
            </p>
          </div>
        </div>

        {/* Title History */}
        {titleHistory.length > 0 && (
          <div style={{ backgroundColor: '#FFFFFF', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '32px', marginBottom: '24px' }}>
            <h3 style={{ fontSize: '22px', fontWeight: 600, color: '#1A1A1A', marginBottom: '24px' }}>Title History</h3>
            {titleHistory.map((row, index) => {
              const combinedCell = row.combinedCell as { status?: string; translatedText?: { en?: string } } | undefined;
              const hasAlert = combinedCell?.status === 'Alert';
              const hasWarning = combinedCell?.status === 'Warning';
              const translatedTitle = row.translatedTitle as { en?: string } | undefined;
              const description = row.description as { translatedTextDisplay?: { translatedDisplay?: { en?: { text?: string } } } } | undefined;
              return (
                <div
                  key={index}
                  style={{
                    backgroundColor: hasAlert ? '#FFE6E6' : hasWarning ? '#FFF9E6' : '#F8F8F7',
                    border: hasAlert ? '1px solid #C94A4A' : hasWarning ? '1px solid #E3B341' : '1px solid #E5E5E5',
                    borderRadius: '4px',
                    padding: '20px',
                    marginBottom: '12px',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px', marginBottom: '8px' }}>
                    {hasAlert ? <AlertTriangle size={20} color="#C94A4A" style={{ flexShrink: 0, marginTop: '2px' }} /> : hasWarning ? <AlertTriangle size={20} color="#E3B341" style={{ flexShrink: 0, marginTop: '2px' }} /> : <Check size={20} color="#3EB489" style={{ flexShrink: 0, marginTop: '2px' }} />}
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '15px', fontWeight: 600, color: '#1A1A1A', marginBottom: '8px' }}>
                        {toMintCheckText(safeStr(translatedTitle?.en ?? (row as Record<string, unknown>).translatedTitle))}
                      </div>
                      <div style={{ fontSize: '14px', color: '#666666', lineHeight: 1.6 }}>
                        {toMintCheckText(safeStr(description?.translatedTextDisplay?.translatedDisplay?.en?.text))}
                      </div>
                      {hasAlert && combinedCell?.translatedText?.en != null && (
                        <div style={{ fontSize: '14px', fontWeight: 600, color: '#C94A4A', marginTop: '8px' }}>{toMintCheckText(safeStr(combinedCell.translatedText.en))}</div>
                      )}
                      {hasWarning && combinedCell?.translatedText?.en != null && (
                        <div style={{ fontSize: '14px', fontWeight: 600, color: '#E3B341', marginTop: '8px' }}>{toMintCheckText(safeStr(combinedCell.translatedText.en))}</div>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Additional History */}
        {additionalHistory.length > 0 && (
          <div style={{ backgroundColor: '#FFFFFF', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '32px', marginBottom: '24px' }}>
            <h3 style={{ fontSize: '22px', fontWeight: 600, color: '#1A1A1A', marginBottom: '8px' }}>Additional History</h3>
            <p style={{ fontSize: '14px', color: '#666666', marginBottom: '24px' }}>Not all accidents / issues are reported</p>
            {additionalHistory.map((row, index) => {
              const combinedCell = row.combinedCell as { status?: string } | undefined;
              const isNormal = combinedCell?.status === 'Normal';
              const translatedTitle = row.translatedTitle as { en?: string } | undefined;
              const description = row.description as { translatedTextDisplay?: { translatedDisplay?: { en?: { text?: string } } } } | undefined;
              return (
                <div key={index} style={{ backgroundColor: '#F8F8F7', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '20px', marginBottom: '12px' }}>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px', marginBottom: '8px' }}>
                    {isNormal ? <Check size={20} color="#3EB489" style={{ flexShrink: 0, marginTop: '2px' }} /> : <AlertTriangle size={20} color="#C94A4A" style={{ flexShrink: 0, marginTop: '2px' }} />}
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '15px', fontWeight: 600, color: '#1A1A1A', marginBottom: '8px' }}>{toMintCheckText(safeStr(translatedTitle?.en))}</div>
                      <div style={{ fontSize: '14px', color: '#666666', lineHeight: 1.6 }}>{toMintCheckText(safeStr(description?.translatedTextDisplay?.translatedDisplay?.en?.text))}</div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Accident/Damage */}
        {accidentDamage.length > 0 && (
          <div style={{ backgroundColor: '#FFFFFF', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '32px', marginBottom: '24px' }}>
            <h3 style={{ fontSize: '22px', fontWeight: 600, color: '#1A1A1A', marginBottom: '8px' }}>Accident / Damage History</h3>
            <p style={{ fontSize: '14px', color: '#666666', marginBottom: '24px' }}>Not all accidents / issues are reported</p>
            {accidentDamage.map((accident, index) => {
              const eventTitleText = accident.eventTitleText as { en?: string } | undefined;
              const comments = accident.comments as { commentsGroups?: { outerLine?: { commentsTextLine?: { text?: string } }; innerLines?: { commentsTextLine?: { text?: string; alert?: boolean } }[] }[] } | undefined;
              const groups = comments?.commentsGroups ?? [];
              return (
                <div key={index} style={{ backgroundColor: '#FFE6E6', border: '2px solid #C94A4A', borderRadius: '4px', padding: '20px', marginBottom: '12px' }}>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px' }}>
                    <AlertTriangle size={24} color="#C94A4A" style={{ flexShrink: 0, marginTop: '2px' }} />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '17px', fontWeight: 600, color: '#1A1A1A', marginBottom: '8px' }}>{toMintCheckText(safeStr(eventTitleText?.en))}</div>
                      <div style={{ fontSize: '14px', color: '#666666', marginBottom: '12px' }}>{toMintCheckText(safeStr(accident.date))}</div>
                      {groups.map((group, gIndex) => (
                        <div key={gIndex}>
                          <div style={{ fontSize: '15px', fontWeight: 600, color: '#1A1A1A', marginBottom: '8px' }}>{toMintCheckText(safeStr(group.outerLine?.commentsTextLine?.text))}</div>
                          {Array.isArray(group.innerLines) && group.innerLines.length > 0 && (
                            <ul style={{ margin: '0 0 0 20px', padding: 0, listStyle: 'disc' }}>
                              {group.innerLines.map((line, lIndex) => (
                                <li key={lIndex} style={{ fontSize: '14px', color: '#666666', marginBottom: '4px' }}>{toMintCheckText(safeStr(line.commentsTextLine?.text))}</li>
                              ))}
                            </ul>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Ownership History - dynamic columns */}
        <div style={{ backgroundColor: '#FFFFFF', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '32px', marginBottom: '24px' }}>
          <h3 style={{ fontSize: '22px', fontWeight: 600, color: '#1A1A1A', marginBottom: '8px' }}>Ownership History</h3>
          <p style={{ fontSize: '14px', color: '#666666', marginBottom: '24px' }}>The number of owners is estimated</p>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ backgroundColor: '#F8F8F7', borderBottom: '2px solid #E5E5E5' }}>
                  <th style={{ padding: '12px', textAlign: 'left', fontSize: '14px', fontWeight: 600, color: '#1A1A1A' }}></th>
                  {numOwnerColumns > 0 && Array.from({ length: numOwnerColumns }, (_, i) => (
                    <th key={i} style={{ padding: '12px', textAlign: 'center', fontSize: '14px', fontWeight: 600, color: '#1A1A1A' }}>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                        <User size={16} />
                        <span>Owner {i + 1}</span>
                      </div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {ownershipHistory.map((row, index) => {
                  const description = row.description as { translatedTextDisplay?: { translatedDisplay?: { en?: { text?: string } } } } | undefined;
                  const cells = (row.cells as { translatedText?: { en?: string }; emptyCell?: boolean }[]) ?? [];
                  return (
                    <tr key={index} style={{ borderBottom: '1px solid #E5E5E5' }}>
                      <td style={{ padding: '12px', fontSize: '14px', color: '#666666' }}>{toMintCheckText(safeStr(description?.translatedTextDisplay?.translatedDisplay?.en?.text))}</td>
                      {cells.map((cell, cIndex) => (
                        <td key={cIndex} style={{ padding: '12px', textAlign: 'center', fontSize: '14px', color: '#1A1A1A', fontWeight: cell.emptyCell ? 400 : 500 }}>
                          {toMintCheckText(safeStr(cell.translatedText?.en)).replace(/&ntilde;/g, 'ñ')}
                        </td>
                      ))}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>

        {/* Detailed History by Owner */}
        <div style={{ backgroundColor: '#FFFFFF', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '32px', marginBottom: '24px' }}>
          <h3 style={{ fontSize: '22px', fontWeight: 600, color: '#1A1A1A', marginBottom: '24px' }}>Detailed History</h3>
          {detailsSection.slice(0, 3).map((owner, ownerIndex) => {
            const tab = owner.tab as { translatedOwner?: { en?: string }; purchaseYear?: { purchaseYear?: string }; ownerType?: { translatedOwnerType?: { en?: string } }; averageMileage?: { displayed?: boolean; averageMilesPerYear?: string } } | undefined;
            const records = (owner.records as { records?: unknown[] })?.records ?? [];
            return (
              <div key={ownerIndex} style={{ marginBottom: '32px' }}>
                <div style={{ backgroundColor: '#F8F8F7', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '16px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <User size={20} color="#3EB489" />
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: '17px', fontWeight: 600, color: '#1A1A1A' }}>{toMintCheckText(safeStr(tab?.translatedOwner?.en ?? (tab as Record<string, unknown>)?.translatedOwner))}</div>
                    <div style={{ fontSize: '14px', color: '#666666', marginTop: '4px' }}>
                      Purchased: {toMintCheckText(safeStr(tab?.purchaseYear?.purchaseYear ?? (tab?.purchaseYear as unknown)))} • {toMintCheckText(safeStr(tab?.ownerType?.translatedOwnerType?.en ?? (tab?.ownerType as Record<string, unknown>)?.translatedOwnerType))}
                      {tab?.averageMileage?.displayed && <span> • {toMintCheckText(safeStr(tab.averageMileage?.averageMilesPerYear))} mi/yr</span>}
                    </div>
                  </div>
                </div>
                <div style={{ paddingLeft: '32px' }}>
                  {(records as Record<string, unknown>[]).slice(0, 5).map((record, rIndex) => {
                    const detailRecordIcon = record.detailRecordIcon as { displayed?: boolean; iconFileName?: string } | undefined;
                    const hasAlertIcon = detailRecordIcon?.displayed && detailRecordIcon?.iconFileName?.includes('alert');
                    const hasServiceIcon = detailRecordIcon?.displayed && detailRecordIcon?.iconFileName?.includes('tools');
                    const source = record.source as { sourceLines?: { displayed?: boolean; sourceTextLine?: { text?: string; hidden?: boolean } }[] } | undefined;
                    const sourceLines = source?.sourceLines ?? [];
                    const comments = record.comments as { commentsGroups?: { outerLine?: { commentsTextLine?: { text?: string; alert?: boolean } }; innerLines?: { commentsTextLine?: { text?: string; alert?: boolean } }[] }[] } | undefined;
                    const commentsGroups = comments?.commentsGroups ?? [];
                    const odometerReading = record.odometerReading as { displayed?: boolean; odometerReading?: string } | undefined;
                    return (
                      <div key={rIndex} style={{ borderLeft: '2px solid #E5E5E5', paddingLeft: '20px', marginBottom: '20px', position: 'relative' }}>
                        <div style={{ position: 'absolute', left: -5, top: 4, width: 8, height: 8, borderRadius: '50%', backgroundColor: hasAlertIcon ? '#C94A4A' : hasServiceIcon ? '#3EB489' : '#666666' }} />
                        <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
                          {hasAlertIcon && <AlertTriangle size={18} color="#C94A4A" style={{ flexShrink: 0, marginTop: '2px' }} />}
                          {hasServiceIcon && <Wrench size={18} color="#3EB489" style={{ flexShrink: 0, marginTop: '2px' }} />}
                          <div style={{ flex: 1 }}>
                            <div style={{ fontSize: '14px', color: '#666666', marginBottom: '4px' }}>
                              {toMintCheckText(safeStr(record.dateDisplay))}
                              {odometerReading?.displayed && <span style={{ marginLeft: '12px', fontWeight: 600, color: '#1A1A1A' }}>{toMintCheckText(safeStr(odometerReading.odometerReading))} mi</span>}
                            </div>
                            <div style={{ fontSize: '13px', color: '#999999', marginBottom: '8px' }}>
                              {sourceLines.filter((line) => line.displayed && !line.sourceTextLine?.hidden).map((line) => toMintCheckText(safeStr(line.sourceTextLine?.text))).join(' • ')}
                            </div>
                            {commentsGroups.map((group, gIndex) => (
                              <div key={gIndex}>
                                <div style={{ fontSize: '15px', fontWeight: 600, color: group.outerLine?.commentsTextLine?.alert ? '#C94A4A' : '#1A1A1A', marginBottom: '6px' }}>{toMintCheckText(safeStr(group.outerLine?.commentsTextLine?.text))}</div>
                                {Array.isArray(group.innerLines) && group.innerLines.length > 0 && (
                                  <ul style={{ margin: '0 0 0 16px', padding: 0, listStyle: 'disc' }}>
                                    {group.innerLines.map((line, lIndex) => (
                                      <li key={lIndex} style={{ fontSize: '14px', color: line.commentsTextLine?.alert ? '#C94A4A' : '#666666', marginBottom: '4px', fontWeight: line.commentsTextLine?.alert ? 600 : 400 }}>{toMintCheckText(safeStr(line.commentsTextLine?.text))}</li>
                                    ))}
                                  </ul>
                                )}
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                  {records.length > 5 && (
                    <div style={{ fontSize: '14px', color: '#3EB489', fontWeight: 600, paddingLeft: '20px', cursor: 'pointer' }}>+ {records.length - 5} more records</div>
                  )}
                </div>
              </div>
            );
          })}
          {detailsSection.length > 3 && (
            <div style={{ backgroundColor: '#E6F4EE', border: '1px solid #3EB489', borderRadius: '4px', padding: '16px', textAlign: 'center' }}>
              <span style={{ fontSize: '15px', fontWeight: 600, color: '#3EB489' }}>+ {detailsSection.length - 3} more owners with detailed records</span>
            </div>
          )}
        </div>

        {/* Footer Disclaimer */}
        <div style={{ backgroundColor: '#FFFFFF', border: '1px solid #E5E5E5', borderRadius: '4px', padding: '32px', marginBottom: '24px' }}>
          <div style={{ display: 'flex', gap: '12px', marginBottom: '20px' }}>
            <Info size={20} color="#666666" style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>
              <p style={{ fontSize: '15px', fontWeight: 600, color: '#1A1A1A', marginBottom: '12px' }}>Important Information</p>
              <p style={{ fontSize: '14px', color: '#666666', lineHeight: 1.6, marginBottom: '12px' }}>
                This report is based on information from multiple sources. MintCheck cannot guarantee the accuracy or completeness of all information. Other problems may not have been reported.
              </p>
              <p style={{ fontSize: '14px', color: '#666666', lineHeight: 1.6, margin: 0 }}>
                <strong style={{ color: '#1A1A1A' }}>Recommendation:</strong> Use this report as one important tool, along with a professional vehicle inspection and test drive, to make an informed decision.
              </p>
            </div>
          </div>
          {hasAlert && (
            <div style={{ backgroundColor: '#FFE6E6', border: '1px solid #C94A4A', borderRadius: '4px', padding: '16px', marginTop: '20px' }}>
              <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
                <AlertTriangle size={20} color="#C94A4A" style={{ flexShrink: 0, marginTop: '2px' }} />
                <p style={{ fontSize: '14px', color: '#1A1A1A', fontWeight: 600, margin: 0 }}>
                  This vehicle has serious title issues. We strongly recommend a thorough inspection by a qualified mechanic before purchase.
                </p>
              </div>
            </div>
          )}
        </div>

        <div style={{ textAlign: 'center', padding: '24px' }}>
          <p style={{ fontSize: '13px', color: '#999999', margin: 0 }}>Report generated {new Date().toLocaleDateString()} • Data provided by third-party sources</p>
        </div>
      </div>
    </div>
  );
}
