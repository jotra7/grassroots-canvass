import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  });

  // Get the pathname - basePath is automatically stripped by Next.js in middleware
  const pathname = request.nextUrl.pathname;
  const isLoginPage = pathname === "/login" || pathname.endsWith("/login");

  // Skip auth check for login page to avoid unnecessary Supabase calls
  if (isLoginPage) {
    return supabaseResponse;
  }

  try {
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll() {
            return request.cookies.getAll();
          },
          setAll(cookiesToSet) {
            cookiesToSet.forEach(({ name, value }) =>
              request.cookies.set(name, value)
            );
            supabaseResponse = NextResponse.next({
              request,
            });
            cookiesToSet.forEach(({ name, value, options }) =>
              supabaseResponse.cookies.set(name, value, options)
            );
          },
        },
      }
    );

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    // If there's an auth error or no user, redirect to login
    if (authError || !user) {
      const url = request.nextUrl.clone();
      url.pathname = "/login";
      return NextResponse.redirect(url);
    }

    // Check if user is admin or team_lead
    const { data: profile, error: profileError } = await supabase
      .from("user_profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profileError || !profile || !["admin", "team_lead"].includes(profile.role)) {
      // Not authorized - redirect to login with error
      const url = request.nextUrl.clone();
      url.pathname = "/login";
      url.searchParams.set("error", "unauthorized");
      return NextResponse.redirect(url);
    }

    return supabaseResponse;
  } catch (error) {
    // If Supabase connection fails, redirect to login
    console.error("Middleware auth error:", error);
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.searchParams.set("error", "connection");
    return NextResponse.redirect(url);
  }
}
