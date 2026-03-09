import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createTransport } from 'npm:nodemailer@6.9.9';

const GMAIL_USER = Deno.env.get('GMAIL_USER') ?? '';
const GMAIL_APP_PASSWORD = Deno.env.get('GMAIL_APP_PASSWORD') ?? '';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    const { to, technicianName, action, adminNotes } = await req.json();

    if (!to || !action) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    let subject = '';
    let bodyHtml = '';
    const name = technicianName ?? 'Technician';
    const notes = adminNotes?.trim() ? adminNotes.trim() : null;

    if (action === 'approved') {
      subject = '🎉 Your FixIT Verification Has Been Approved!';
      bodyHtml = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #1E3A8A, #3B82F6); padding: 32px; border-radius: 12px 12px 0 0; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 24px;">FixIT Technician Verification</h1>
          </div>
          <div style="background: #f9fafb; padding: 32px; border-radius: 0 0 12px 12px; border: 1px solid #e5e7eb;">
            <h2 style="color: #111827;">Congratulations, ${name}! 🎉</h2>
            <p style="color: #4b5563; font-size: 16px; line-height: 1.6;">
              Your technician verification has been <strong style="color: #10B981;">approved</strong>.
              You can now log in and start accepting repair jobs on FixIT.
            </p>
            ${notes ? `
            <div style="background: #f0fdf4; border-left: 4px solid #10B981; padding: 16px; border-radius: 8px; margin: 20px 0;">
              <p style="margin: 0; color: #166534; font-weight: bold;">Note from Admin:</p>
              <p style="margin: 8px 0 0; color: #166534;">${notes}</p>
            </div>` : ''}
            <p style="color: #6b7280; font-size: 14px; margin-top: 24px;">
              Open the FixIT app to get started. Welcome to the team!
            </p>
          </div>
        </div>`;
    } else if (action === 'rejected') {
      subject = 'FixIT Verification Update — Action Required';
      bodyHtml = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #1E3A8A, #3B82F6); padding: 32px; border-radius: 12px 12px 0 0; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 24px;">FixIT Technician Verification</h1>
          </div>
          <div style="background: #f9fafb; padding: 32px; border-radius: 0 0 12px 12px; border: 1px solid #e5e7eb;">
            <h2 style="color: #111827;">Hi ${name},</h2>
            <p style="color: #4b5563; font-size: 16px; line-height: 1.6;">
              Unfortunately, your technician verification has been <strong style="color: #EF4444;">rejected</strong>.
            </p>
            ${notes ? `
            <div style="background: #fef2f2; border-left: 4px solid #EF4444; padding: 16px; border-radius: 8px; margin: 20px 0;">
              <p style="margin: 0; color: #991b1b; font-weight: bold;">Reason from Admin:</p>
              <p style="margin: 8px 0 0; color: #991b1b;">${notes}</p>
            </div>` : ''}
            <p style="color: #6b7280; font-size: 14px; margin-top: 24px;">
              If you believe this is a mistake or have questions, please contact our support team.
            </p>
          </div>
        </div>`;
    } else if (action === 'resubmit') {
      subject = 'FixIT Verification — Resubmission Required';
      bodyHtml = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #1E3A8A, #3B82F6); padding: 32px; border-radius: 12px 12px 0 0; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 24px;">FixIT Technician Verification</h1>
          </div>
          <div style="background: #f9fafb; padding: 32px; border-radius: 0 0 12px 12px; border: 1px solid #e5e7eb;">
            <h2 style="color: #111827;">Hi ${name},</h2>
            <p style="color: #4b5563; font-size: 16px; line-height: 1.6;">
              Our admin team has reviewed your verification and is requesting a <strong style="color: #F59E0B;">resubmission</strong> with some corrections.
            </p>
            ${notes ? `
            <div style="background: #fffbeb; border-left: 4px solid #F59E0B; padding: 16px; border-radius: 8px; margin: 20px 0;">
              <p style="margin: 0; color: #92400e; font-weight: bold;">Required Changes from Admin:</p>
              <p style="margin: 8px 0 0; color: #92400e;">${notes}</p>
            </div>` : ''}
            <p style="color: #6b7280; font-size: 14px; margin-top: 24px;">
              Please open the FixIT app and resubmit your verification documents with the requested changes.
            </p>
          </div>
        </div>`;
    } else {
      return new Response(JSON.stringify({ error: 'Unknown action' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const transporter = createTransport({
      host: 'smtp.gmail.com',
      port: 465,
      secure: true,
      auth: {
        user: GMAIL_USER,
        pass: GMAIL_APP_PASSWORD,
      },
    });

    await transporter.sendMail({
      from: `FixIT <${GMAIL_USER}>`,
      to,
      subject,
      html: bodyHtml,
    });

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
