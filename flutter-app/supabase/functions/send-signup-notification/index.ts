import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const FROM_EMAIL = Deno.env.get("FROM_EMAIL") || "Grassroots Canvass <notifications@yourdomain.com>";

interface SignupNotification {
  admin_emails: string[];
  new_user_name: string;
  new_user_email: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    const { admin_emails, new_user_name, new_user_email }: SignupNotification = await req.json();

    if (!admin_emails || admin_emails.length === 0) {
      return new Response(JSON.stringify({ error: "No admin emails provided" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!RESEND_API_KEY) {
      console.error("RESEND_API_KEY not configured");
      return new Response(JSON.stringify({ error: "Email service not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Send email to each admin
    const emailPromises = admin_emails.map(async (adminEmail: string) => {
      const response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: FROM_EMAIL,
          to: adminEmail,
          subject: `New Canvass Signup: ${new_user_name}`,
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #2563eb;">New User Signup</h2>
              <p>A new user has signed up for Grassroots Canvass and is waiting for approval:</p>

              <div style="background-color: #f3f4f6; padding: 16px; border-radius: 8px; margin: 16px 0;">
                <p style="margin: 0;"><strong>Name:</strong> ${new_user_name}</p>
                <p style="margin: 8px 0 0 0;"><strong>Email:</strong> ${new_user_email}</p>
              </div>

              <p>Please open the Grassroots Canvass app to approve or reject this user.</p>

              <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 24px 0;">
              <p style="color: #6b7280; font-size: 12px;">
                This is an automated notification from Grassroots Canvass.
              </p>
            </div>
          `,
        }),
      });

      if (!response.ok) {
        const error = await response.text();
        console.error(`Failed to send email to ${adminEmail}:`, error);
        return { email: adminEmail, success: false, error };
      }

      return { email: adminEmail, success: true };
    });

    const results = await Promise.all(emailPromises);
    const successful = results.filter((r) => r.success).length;

    return new Response(
      JSON.stringify({
        message: `Sent ${successful}/${admin_emails.length} notification emails`,
        results,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
