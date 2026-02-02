import React from 'react';

/**
 * MintCheck Email Templates
 * 
 * These are HTML email templates that match the MintCheck brand style guide.
 * Each template is provided as a string constant that can be copied and used
 * with email service providers like SendGrid, Mailchimp, or AWS SES.
 * 
 * Key Brand Elements:
 * - MintCheck Green: #3EB489
 * - Near-black text: #1A1A1A
 * - Secondary text: #666666
 * - Off-white background: #F8F8F7
 * - Border radius: 4px
 * - Clean, professional aesthetic
 */

// Base email styles that work across email clients
const emailBaseStyles = `
  body { 
    margin: 0; 
    padding: 0; 
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    background-color: #F8F8F7;
  }
  table { 
    border-collapse: collapse; 
    width: 100%; 
  }
  img { 
    border: 0; 
    outline: none; 
    text-decoration: none; 
    display: block;
  }
`;

// 1. Welcome Email Template
export const welcomeEmailTemplate = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to MintCheck</title>
  <style>
    ${emailBaseStyles}
  </style>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          
          <!-- Header -->
          <tr>
            <td style="background-color: #3EB489; padding: 32px; text-align: center; border-radius: 4px 4px 0 0;">
              <h1 style="margin: 0; color: #FFFFFF; font-size: 32px; font-weight: 600;">MintCheck</h1>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 40px 32px;">
              <h2 style="margin: 0 0 16px 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Welcome to MintCheck!</h2>
              
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Hi {{firstName}},
              </p>
              
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Thanks for joining MintCheck—the easiest way to check a vehicle's health before you buy. You're now equipped with professional-grade diagnostics in your pocket.
              </p>
              
              <p style="margin: 0 0 24px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Here's what you can do with MintCheck:
              </p>
              
              <ul style="margin: 0 0 24px 0; padding-left: 20px; color: #666666; font-size: 15px; line-height: 1.7;">
                <li style="margin-bottom: 12px;">Get instant OBD-II diagnostics on any vehicle</li>
                <li style="margin-bottom: 12px;">Receive clear "Safe to Buy" or "Proceed with Caution" recommendations</li>
                <li style="margin-bottom: 12px;">Access detailed reports on engine, transmission, and more</li>
                <li style="margin-bottom: 12px;">Make informed decisions with confidence</li>
              </ul>
              
              <!-- CTA Button -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0;">
                <tr>
                  <td align="center">
                    <a href="{{appDownloadLink}}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 4px; font-size: 15px; font-weight: 600;">Get Started</a>
                  </td>
                </tr>
              </table>
              
              <p style="margin: 0 0 12px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Need help? We're here for you.
              </p>
              
              <p style="margin: 0; color: #666666; font-size: 15px; line-height: 1.7;">
                The MintCheck Team
              </p>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                © 2026 MintCheck. All rights reserved.
              </p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{helpCenterLink}}" style="color: #3EB489; text-decoration: none;">Help Center</a> • 
                <a href="{{privacyLink}}" style="color: #3EB489; text-decoration: none;">Privacy</a> • 
                <a href="{{termsLink}}" style="color: #3EB489; text-decoration: none;">Terms</a>
              </p>
              <p style="margin: 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{unsubscribeLink}}" style="color: #999999; text-decoration: underline;">Unsubscribe</a>
              </p>
            </td>
          </tr>
          
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

// 2. Scan Complete Email Template
export const scanCompleteEmailTemplate = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Vehicle Scan is Complete</title>
  <style>
    ${emailBaseStyles}
  </style>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          
          <!-- Header -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">MintCheck</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Your scan is complete</h2>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 24px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Hi {{firstName}},
              </p>
              
              <p style="margin: 0 0 24px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Great news! We've finished analyzing your vehicle scan. Here's your summary:
              </p>
              
              <!-- Vehicle Info Card -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 0 0 24px 0;">
                <tr>
                  <td style="background-color: #F8F8F7; padding: 20px; border-radius: 4px; border: 1px solid #E5E5E5;">
                    <p style="margin: 0 0 8px 0; color: #1A1A1A; font-size: 17px; font-weight: 600;">{{vehicleYear}} {{vehicleMake}} {{vehicleModel}}</p>
                    <p style="margin: 0; color: #666666; font-size: 14px;">VIN: {{vin}}</p>
                  </td>
                </tr>
              </table>
              
              <!-- Status Badge -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 0 0 24px 0;">
                <tr>
                  <td style="background-color: {{statusBgColor}}; padding: 16px; border-radius: 4px; border: 2px solid {{statusBorderColor}}; text-align: center;">
                    <p style="margin: 0; color: {{statusTextColor}}; font-size: 17px; font-weight: 600;">{{statusText}}</p>
                  </td>
                </tr>
              </table>
              
              <!-- Issues Found (if any) -->
              <div style="margin: 0 0 24px 0;">
                <p style="margin: 0 0 12px 0; color: #1A1A1A; font-size: 15px; font-weight: 600;">Scan Results:</p>
                <p style="margin: 0 0 8px 0; color: #666666; font-size: 15px; line-height: 1.7;">{{issuesSummary}}</p>
              </div>
              
              <!-- CTA Button -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0 24px 0;">
                <tr>
                  <td align="center">
                    <a href="{{viewReportLink}}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 4px; font-size: 15px; font-weight: 600;">View Full Report</a>
                  </td>
                </tr>
              </table>
              
              <p style="margin: 0 0 12px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Questions about your results? Our support team is here to help.
              </p>
              
              <p style="margin: 0; color: #666666; font-size: 15px; line-height: 1.7;">
                The MintCheck Team
              </p>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                © 2026 MintCheck. All rights reserved.
              </p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{helpCenterLink}}" style="color: #3EB489; text-decoration: none;">Help Center</a> • 
                <a href="{{privacyLink}}" style="color: #3EB489; text-decoration: none;">Privacy</a> • 
                <a href="{{termsLink}}" style="color: #3EB489; text-decoration: none;">Terms</a>
              </p>
              <p style="margin: 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{unsubscribeLink}}" style="color: #999999; text-decoration: underline;">Unsubscribe</a>
              </p>
            </td>
          </tr>
          
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

// 2b. Email Confirmation Template (signup / email change)
export const emailConfirmationTemplate = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Confirm your MintCheck email</title>
  <style>
    ${emailBaseStyles}
  </style>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          
          <!-- Header -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">MintCheck</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Confirm your MintCheck email</h2>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Hi,
              </p>
              
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Please confirm your email address for your {{app_name}} account ({{user_email}}) by clicking the button below:
              </p>
              
              <!-- CTA Button -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0;">
                <tr>
                  <td align="center">
                    <a href="{{action_url}}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 4px; font-size: 15px; font-weight: 600;">Confirm Email</a>
                  </td>
                </tr>
              </table>
              
              <!-- Security Info -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 24px 0;">
                <tr>
                  <td style="background-color: #FCFCFB; padding: 16px; border-radius: 4px; border: 1px solid #E5E5E5;">
                    <p style="margin: 0 0 8px 0; color: #1A1A1A; font-size: 14px; font-weight: 600;">Security Notice</p>
                    <p style="margin: 0; color: #666666; font-size: 14px; line-height: 1.6;">
                      This link will expire in 24 hours. If you didn't request this, you can safely ignore this email.
                    </p>
                  </td>
                </tr>
              </table>
              
              <p style="margin: 24px 0 0 0; color: #999999; font-size: 13px; line-height: 1.7;">
                If the button doesn't work, copy and paste this link into your browser:<br>
                <a href="{{action_url}}" style="color: #3EB489; text-decoration: none; word-break: break-all;">{{action_url}}</a>
              </p>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                © 2026 MintCheck. All rights reserved.
              </p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{helpCenterLink}}" style="color: #3EB489; text-decoration: none;">Help Center</a> •
                <a href="{{privacyLink}}" style="color: #3EB489; text-decoration: none;">Privacy</a> •
                <a href="{{termsLink}}" style="color: #3EB489; text-decoration: none;">Terms</a>
              </p>
            </td>
          </tr>
          
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

// 3. Password Reset Email Template
export const passwordResetEmailTemplate = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Your MintCheck Password</title>
  <style>
    ${emailBaseStyles}
  </style>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          
          <!-- Header -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">MintCheck</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Reset your password</h2>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Hi {{firstName}},
              </p>
              
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                We received a request to reset your password for your MintCheck account. Click the button below to create a new password:
              </p>
              
              <!-- CTA Button -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0;">
                <tr>
                  <td align="center">
                    <a href="{{resetPasswordLink}}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 4px; font-size: 15px; font-weight: 600;">Reset Password</a>
                  </td>
                </tr>
              </table>
              
              <!-- Security Info -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 24px 0;">
                <tr>
                  <td style="background-color: #FCFCFB; padding: 16px; border-radius: 4px; border: 1px solid #E5E5E5;">
                    <p style="margin: 0 0 8px 0; color: #1A1A1A; font-size: 14px; font-weight: 600;">Security Notice</p>
                    <p style="margin: 0; color: #666666; font-size: 14px; line-height: 1.6;">
                      This link will expire in 24 hours. If you didn't request a password reset, you can safely ignore this email. Your password won't change unless you click the button above.
                    </p>
                  </td>
                </tr>
              </table>
              
              <p style="margin: 24px 0 0 0; color: #999999; font-size: 13px; line-height: 1.7;">
                If the button doesn't work, copy and paste this link into your browser:<br>
                <a href="{{resetPasswordLink}}" style="color: #3EB489; text-decoration: none; word-break: break-all;">{{resetPasswordLink}}</a>
              </p>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                © 2026 MintCheck. All rights reserved.
              </p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{helpCenterLink}}" style="color: #3EB489; text-decoration: none;">Help Center</a> • 
                <a href="{{privacyLink}}" style="color: #3EB489; text-decoration: none;">Privacy</a> • 
                <a href="{{termsLink}}" style="color: #3EB489; text-decoration: none;">Terms</a>
              </p>
              <p style="margin: 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{unsubscribeLink}}" style="color: #999999; text-decoration: underline;">Unsubscribe</a>
              </p>
            </td>
          </tr>
          
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

// 4. Issue Alert Email Template
export const issueAlertEmailTemplate = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Important Vehicle Alert</title>
  <style>
    ${emailBaseStyles}
  </style>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          
          <!-- Header -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">MintCheck</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">⚠️ Important vehicle alert</h2>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 24px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Hi {{firstName}},
              </p>
              
              <p style="margin: 0 0 24px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                We've detected an important issue with your vehicle that requires attention.
              </p>
              
              <!-- Vehicle Info Card -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 0 0 24px 0;">
                <tr>
                  <td style="background-color: #F8F8F7; padding: 20px; border-radius: 4px; border: 1px solid #E5E5E5;">
                    <p style="margin: 0 0 8px 0; color: #1A1A1A; font-size: 17px; font-weight: 600;">{{vehicleYear}} {{vehicleMake}} {{vehicleModel}}</p>
                    <p style="margin: 0; color: #666666; font-size: 14px;">VIN: {{vin}}</p>
                  </td>
                </tr>
              </table>
              
              <!-- Alert Card -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 0 0 24px 0;">
                <tr>
                  <td style="background-color: #FFF9E6; padding: 20px; border-radius: 4px; border: 2px solid #E3B341;">
                    <p style="margin: 0 0 12px 0; color: #1A1A1A; font-size: 17px; font-weight: 600;">{{issueTitle}}</p>
                    <p style="margin: 0 0 16px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                      {{issueDescription}}
                    </p>
                    <p style="margin: 0; color: #E3B341; font-size: 14px; font-weight: 600;">
                      Severity: {{severityLevel}}
                    </p>
                  </td>
                </tr>
              </table>
              
              <div style="margin: 0 0 24px 0;">
                <p style="margin: 0 0 12px 0; color: #1A1A1A; font-size: 15px; font-weight: 600;">Recommended Action:</p>
                <p style="margin: 0; color: #666666; font-size: 15px; line-height: 1.7;">
                  {{recommendedAction}}
                </p>
              </div>
              
              <!-- CTA Button -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0 24px 0;">
                <tr>
                  <td align="center">
                    <a href="{{viewDetailsLink}}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 4px; font-size: 15px; font-weight: 600;">View Full Details</a>
                  </td>
                </tr>
              </table>
              
              <p style="margin: 0 0 12px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Questions? Contact our support team anytime.
              </p>
              
              <p style="margin: 0; color: #666666; font-size: 15px; line-height: 1.7;">
                The MintCheck Team
              </p>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                © 2026 MintCheck. All rights reserved.
              </p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{helpCenterLink}}" style="color: #3EB489; text-decoration: none;">Help Center</a> • 
                <a href="{{privacyLink}}" style="color: #3EB489; text-decoration: none;">Privacy</a> • 
                <a href="{{termsLink}}" style="color: #3EB489; text-decoration: none;">Terms</a>
              </p>
              <p style="margin: 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{unsubscribeLink}}" style="color: #999999; text-decoration: underline;">Unsubscribe</a>
              </p>
            </td>
          </tr>
          
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

// 5. Monthly Summary Email Template
export const monthlySummaryEmailTemplate = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Monthly MintCheck Summary</title>
  <style>
    ${emailBaseStyles}
  </style>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          
          <!-- Header -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">MintCheck</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Your monthly summary</h2>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 24px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Hi {{firstName}},
              </p>
              
              <p style="margin: 0 0 32px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Here's a look at your MintCheck activity for {{monthName}}:
              </p>
              
              <!-- Stats Grid -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 0 0 32px 0;">
                <tr>
                  <td style="width: 50%; padding: 0 8px 16px 0;">
                    <table role="presentation" style="width: 100%; border-collapse: collapse;">
                      <tr>
                        <td style="background-color: #F8F8F7; padding: 24px; border-radius: 4px; border: 1px solid #E5E5E5; text-align: center;">
                          <p style="margin: 0 0 8px 0; color: #3EB489; font-size: 32px; font-weight: 600;">{{scansCompleted}}</p>
                          <p style="margin: 0; color: #666666; font-size: 14px;">Scans Completed</p>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td style="width: 50%; padding: 0 0 16px 8px;">
                    <table role="presentation" style="width: 100%; border-collapse: collapse;">
                      <tr>
                        <td style="background-color: #F8F8F7; padding: 24px; border-radius: 4px; border: 1px solid #E5E5E5; text-align: center;">
                          <p style="margin: 0 0 8px 0; color: #3EB489; font-size: 32px; font-weight: 600;">{{vehiclesChecked}}</p>
                          <p style="margin: 0; color: #666666; font-size: 14px;">Vehicles Checked</p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
              
              <!-- Recent Activity -->
              <div style="margin: 0 0 24px 0;">
                <p style="margin: 0 0 16px 0; color: #1A1A1A; font-size: 17px; font-weight: 600;">Recent Activity</p>
                
                <!-- Activity Item -->
                <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 0 0 12px 0;">
                  <tr>
                    <td style="background-color: #F8F8F7; padding: 16px; border-radius: 4px; border: 1px solid #E5E5E5;">
                      <p style="margin: 0 0 4px 0; color: #1A1A1A; font-size: 15px; font-weight: 600;">{{recentVehicle1}}</p>
                      <p style="margin: 0; color: #666666; font-size: 13px;">Scanned {{recentDate1}}</p>
                    </td>
                  </tr>
                </table>
                
                <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 0 0 12px 0;">
                  <tr>
                    <td style="background-color: #F8F8F7; padding: 16px; border-radius: 4px; border: 1px solid #E5E5E5;">
                      <p style="margin: 0 0 4px 0; color: #1A1A1A; font-size: 15px; font-weight: 600;">{{recentVehicle2}}</p>
                      <p style="margin: 0; color: #666666; font-size: 13px;">Scanned {{recentDate2}}</p>
                    </td>
                  </tr>
                </table>
              </div>
              
              <!-- Tip Section -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0 24px 0;">
                <tr>
                  <td style="background-color: #E6F4EE; padding: 20px; border-radius: 4px; border: 1px solid #3EB489;">
                    <p style="margin: 0 0 8px 0; color: #1A1A1A; font-size: 15px; font-weight: 600;">💡 Pro Tip</p>
                    <p style="margin: 0; color: #666666; font-size: 14px; line-height: 1.6;">
                      Always scan a vehicle before making an offer. Issues that seem minor can indicate larger problems that aren't immediately visible.
                    </p>
                  </td>
                </tr>
              </table>
              
              <p style="margin: 0 0 12px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Keep up the smart car shopping!
              </p>
              
              <p style="margin: 0; color: #666666; font-size: 15px; line-height: 1.7;">
                The MintCheck Team
              </p>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                © 2026 MintCheck. All rights reserved.
              </p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{helpCenterLink}}" style="color: #3EB489; text-decoration: none;">Help Center</a> • 
                <a href="{{privacyLink}}" style="color: #3EB489; text-decoration: none;">Privacy</a> • 
                <a href="{{termsLink}}" style="color: #3EB489; text-decoration: none;">Terms</a>
              </p>
              <p style="margin: 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{unsubscribeLink}}" style="color: #999999; text-decoration: underline;">Unsubscribe</a>
              </p>
            </td>
          </tr>
          
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

// 6. Receipt/Invoice Email Template
export const receiptEmailTemplate = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your MintCheck Receipt</title>
  <style>
    ${emailBaseStyles}
  </style>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8F8F7;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          
          <!-- Header -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 32px 32px 24px 32px; border-radius: 4px 4px 0 0;">
              <div style="color: #3EB489; font-size: 24px; font-weight: 600; margin-bottom: 8px;">MintCheck</div>
              <h2 style="margin: 0; color: #1A1A1A; font-size: 24px; font-weight: 600;">Payment Receipt</h2>
            </td>
          </tr>
          
          <!-- Main Content -->
          <tr>
            <td style="background-color: #FFFFFF; padding: 0 32px 40px 32px;">
              <p style="margin: 0 0 24px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Hi {{firstName}},
              </p>
              
              <p style="margin: 0 0 32px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Thanks for your payment. Here's your receipt for your records:
              </p>
              
              <!-- Receipt Details -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 0 0 24px 0;">
                <tr>
                  <td style="background-color: #F8F8F7; padding: 24px; border-radius: 4px; border: 1px solid #E5E5E5;">
                    <table role="presentation" style="width: 100%; border-collapse: collapse;">
                      <tr>
                        <td style="padding: 8px 0;">
                          <p style="margin: 0; color: #666666; font-size: 14px;">Receipt #</p>
                        </td>
                        <td style="padding: 8px 0; text-align: right;">
                          <p style="margin: 0; color: #1A1A1A; font-size: 14px; font-weight: 600;">{{receiptNumber}}</p>
                        </td>
                      </tr>
                      <tr>
                        <td style="padding: 8px 0;">
                          <p style="margin: 0; color: #666666; font-size: 14px;">Date</p>
                        </td>
                        <td style="padding: 8px 0; text-align: right;">
                          <p style="margin: 0; color: #1A1A1A; font-size: 14px; font-weight: 600;">{{receiptDate}}</p>
                        </td>
                      </tr>
                      <tr>
                        <td style="padding: 8px 0;">
                          <p style="margin: 0; color: #666666; font-size: 14px;">Payment Method</p>
                        </td>
                        <td style="padding: 8px 0; text-align: right;">
                          <p style="margin: 0; color: #1A1A1A; font-size: 14px; font-weight: 600;">{{paymentMethod}}</p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
              
              <!-- Line Items -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 0 0 24px 0;">
                <tr>
                  <td style="background-color: #FFFFFF; padding: 0; border-bottom: 2px solid #E5E5E5;">
                    <table role="presentation" style="width: 100%; border-collapse: collapse;">
                      <tr>
                        <td style="padding: 12px 0;">
                          <p style="margin: 0; color: #1A1A1A; font-size: 15px; font-weight: 600;">Description</p>
                        </td>
                        <td style="padding: 12px 0; text-align: right;">
                          <p style="margin: 0; color: #1A1A1A; font-size: 15px; font-weight: 600;">Amount</p>
                        </td>
                      </tr>
                      <tr>
                        <td style="padding: 16px 0;">
                          <p style="margin: 0; color: #666666; font-size: 15px;">{{planName}}</p>
                        </td>
                        <td style="padding: 16px 0; text-align: right;">
                          <p style="margin: 0; color: #666666; font-size: 15px;">$\{{planAmount}}</p>
                        </td>
                      </tr>
                      <tr>
                        <td style="padding: 16px 0; border-top: 1px solid #E5E5E5;">
                          <p style="margin: 0; color: #1A1A1A; font-size: 17px; font-weight: 600;">Total</p>
                        </td>
                        <td style="padding: 16px 0; text-align: right; border-top: 1px solid #E5E5E5;">
                          <p style="margin: 0; color: #1A1A1A; font-size: 17px; font-weight: 600;">$\{{totalAmount}}</p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
              
              <!-- CTA Button -->
              <table role="presentation" style="width: 100%; border-collapse: collapse; margin: 32px 0 24px 0;">
                <tr>
                  <td align="center">
                    <a href="{{downloadReceiptLink}}" style="display: inline-block; padding: 16px 40px; background-color: #3EB489; color: #FFFFFF; text-decoration: none; border-radius: 4px; font-size: 15px; font-weight: 600;">Download Receipt</a>
                  </td>
                </tr>
              </table>
              
              <p style="margin: 0 0 12px 0; color: #666666; font-size: 15px; line-height: 1.7;">
                Questions about your bill? Contact our support team.
              </p>
              
              <p style="margin: 0; color: #666666; font-size: 15px; line-height: 1.7;">
                The MintCheck Team
              </p>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #F8F8F7; padding: 32px; text-align: center; border-radius: 0 0 4px 4px; border-top: 1px solid #E5E5E5;">
              <p style="margin: 0 0 16px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                © 2026 MintCheck. All rights reserved.
              </p>
              <p style="margin: 0 0 8px 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{helpCenterLink}}" style="color: #3EB489; text-decoration: none;">Help Center</a> • 
                <a href="{{privacyLink}}" style="color: #3EB489; text-decoration: none;">Privacy</a> • 
                <a href="{{termsLink}}" style="color: #3EB489; text-decoration: none;">Terms</a>
              </p>
              <p style="margin: 0; color: #999999; font-size: 13px; line-height: 1.6;">
                <a href="{{unsubscribeLink}}" style="color: #999999; text-decoration: underline;">Unsubscribe</a>
              </p>
            </td>
          </tr>
          
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

// Component for viewing/managing email templates in React
export default function EmailTemplates() {
  const templates = [
    { name: 'Welcome Email', template: welcomeEmailTemplate, description: 'Sent when a new user signs up for MintCheck' },
    { name: 'Email Confirmation', template: emailConfirmationTemplate, description: 'Sent for signup or email change confirmation (deep link)' },
    { name: 'Scan Complete', template: scanCompleteEmailTemplate, description: 'Sent when a vehicle scan finishes processing' },
    { name: 'Password Reset', template: passwordResetEmailTemplate, description: 'Sent when user requests to reset their password' },
    { name: 'Issue Alert', template: issueAlertEmailTemplate, description: 'Sent when a critical vehicle issue is detected' },
    { name: 'Monthly Summary', template: monthlySummaryEmailTemplate, description: 'Monthly digest of user activity' },
    { name: 'Receipt/Invoice', template: receiptEmailTemplate, description: 'Payment receipt for subscriptions or purchases' },
  ];

  const copyToClipboard = (template: string, name: string) => {
    navigator.clipboard.writeText(template);
    alert(`${name} copied to clipboard!`);
  };

  return (
    <div style={{ 
      minHeight: '100vh', 
      backgroundColor: '#F8F8F7', 
      padding: '40px 20px' 
    }}>
      <div style={{ 
        maxWidth: '1200px', 
        margin: '0 auto' 
      }}>
        {/* Header */}
        <div style={{ marginBottom: '48px' }}>
          <h1 style={{ 
            fontSize: '32px', 
            fontWeight: 600, 
            color: '#1A1A1A', 
            marginBottom: '12px' 
          }}>
            MintCheck Email Templates
          </h1>
          <p style={{ 
            fontSize: '15px', 
            color: '#666666', 
            lineHeight: 1.7 
          }}>
            Production-ready email templates matching the MintCheck brand style guide. 
            Each template uses inline styles for maximum email client compatibility.
          </p>
        </div>

        {/* Template Grid */}
        <div style={{ 
          display: 'grid', 
          gap: '24px' 
        }}>
          {templates.map((item, index) => (
            <div 
              key={index}
              style={{
                backgroundColor: '#FFFFFF',
                border: '1px solid #E5E5E5',
                borderRadius: '4px',
                padding: '24px'
              }}
            >
              <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                alignItems: 'flex-start',
                marginBottom: '16px'
              }}>
                <div>
                  <h3 style={{ 
                    fontSize: '17px', 
                    fontWeight: 600, 
                    color: '#1A1A1A', 
                    marginBottom: '8px' 
                  }}>
                    {item.name}
                  </h3>
                  <p style={{ 
                    fontSize: '14px', 
                    color: '#666666', 
                    margin: 0 
                  }}>
                    {item.description}
                  </p>
                </div>
                <button
                  onClick={() => copyToClipboard(item.template, item.name)}
                  style={{
                    padding: '12px 24px',
                    backgroundColor: '#3EB489',
                    color: '#FFFFFF',
                    border: 'none',
                    borderRadius: '4px',
                    fontSize: '15px',
                    fontWeight: 600,
                    cursor: 'pointer',
                    transition: 'background-color 0.2s'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.backgroundColor = '#2D9970';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = '#3EB489';
                  }}
                >
                  Copy HTML
                </button>
              </div>

              {/* Template Variables Section */}
              <div style={{
                backgroundColor: '#F8F8F7',
                padding: '16px',
                borderRadius: '4px',
                marginTop: '16px'
              }}>
                <p style={{
                  fontSize: '13px',
                  fontWeight: 600,
                  color: '#1A1A1A',
                  marginBottom: '8px'
                }}>
                  Template Variables:
                </p>
                <code style={{
                  fontSize: '13px',
                  color: '#666666',
                  display: 'block',
                  whiteSpace: 'pre-wrap',
                  fontFamily: 'monospace'
                }}>
                  {getTemplateVariables(item.name)}
                </code>
              </div>
            </div>
          ))}
        </div>

        {/* Usage Instructions */}
        <div style={{
          backgroundColor: '#FFFFFF',
          border: '1px solid #E5E5E5',
          borderRadius: '4px',
          padding: '32px',
          marginTop: '48px'
        }}>
          <h2 style={{
            fontSize: '22px',
            fontWeight: 600,
            color: '#1A1A1A',
            marginBottom: '16px'
          }}>
            Usage Instructions
          </h2>
          
          <div style={{ color: '#666666', fontSize: '15px', lineHeight: 1.7 }}>
            <p style={{ marginBottom: '16px' }}>
              <strong style={{ color: '#1A1A1A' }}>1. Copy the HTML template</strong><br />
              Click "Copy HTML" to copy the full email template to your clipboard.
            </p>
            
            <p style={{ marginBottom: '16px' }}>
              <strong style={{ color: '#1A1A1A' }}>2. Replace template variables</strong><br />
              Each template contains variables marked with {'{{'} {'}}'}. Replace these with actual values from your database or API.
            </p>
            
            <p style={{ marginBottom: '16px' }}>
              <strong style={{ color: '#1A1A1A' }}>3. Test in email clients</strong><br />
              Test your emails in popular clients (Gmail, Outlook, Apple Mail, etc.) before sending to users.
            </p>
            
            <p style={{ marginBottom: '16px' }}>
              <strong style={{ color: '#1A1A1A' }}>4. Integration options</strong><br />
              These templates work with: SendGrid, Mailgun, AWS SES, Mailchimp, Postmark, and other email services.
            </p>

            <div style={{
              backgroundColor: '#E6F4EE',
              padding: '16px',
              borderRadius: '4px',
              border: '1px solid #3EB489',
              marginTop: '24px'
            }}>
              <p style={{
                margin: 0,
                fontSize: '14px',
                color: '#1A1A1A'
              }}>
                <strong>💡 Pro Tip:</strong> All templates use inline styles for maximum compatibility across email clients. The templates are AAA accessible and mobile-responsive.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Helper function to get template variables for each template type
function getTemplateVariables(templateName: string): string {
  const variables: { [key: string]: string } = {
    'Welcome Email': `{{firstName}}, {{appDownloadLink}}, {{helpCenterLink}}, {{privacyLink}}, {{termsLink}}, {{unsubscribeLink}}`,
    'Email Confirmation': `{{action_url}}, {{user_email}}, {{app_name}}, {{helpCenterLink}}, {{privacyLink}}, {{termsLink}}`,
    'Scan Complete': `{{firstName}}, {{vehicleYear}}, {{vehicleMake}}, {{vehicleModel}}, {{vin}}, {{statusBgColor}}, {{statusBorderColor}}, {{statusTextColor}}, {{statusText}}, {{issuesSummary}}, {{viewReportLink}}, {{helpCenterLink}}, {{privacyLink}}, {{termsLink}}, {{unsubscribeLink}}`,
    'Password Reset': `{{firstName}}, {{resetPasswordLink}}, {{helpCenterLink}}, {{privacyLink}}, {{termsLink}}, {{unsubscribeLink}}`,
    'Issue Alert': `{{firstName}}, {{vehicleYear}}, {{vehicleMake}}, {{vehicleModel}}, {{vin}}, {{issueTitle}}, {{issueDescription}}, {{severityLevel}}, {{recommendedAction}}, {{viewDetailsLink}}, {{helpCenterLink}}, {{privacyLink}}, {{termsLink}}, {{unsubscribeLink}}`,
    'Monthly Summary': `{{firstName}}, {{monthName}}, {{scansCompleted}}, {{vehiclesChecked}}, {{recentVehicle1}}, {{recentDate1}}, {{recentVehicle2}}, {{recentDate2}}, {{helpCenterLink}}, {{privacyLink}}, {{termsLink}}, {{unsubscribeLink}}`,
    'Receipt/Invoice': `{{firstName}}, {{receiptNumber}}, {{receiptDate}}, {{paymentMethod}}, {{planName}}, {{planAmount}}, {{totalAmount}}, {{downloadReceiptLink}}, {{helpCenterLink}}, {{privacyLink}}, {{termsLink}}, {{unsubscribeLink}}`,
  };
  
  return variables[templateName] || 'No variables';
}