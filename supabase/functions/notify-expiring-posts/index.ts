// supabase/functions/notify-expiring-posts/index.ts
//
// Runs daily (via a pg_cron schedule set in Supabase).
// Finds posts expiring in the next 24 hours and inserts a
// 'post_expiry' notification for each post owner.
//
// Deploy with:  supabase functions deploy notify-expiring-posts
// Schedule in Supabase Dashboard → Database → Extensions → pg_cron:
//   select cron.schedule(
//     'notify-expiring-posts',
//     '0 9 * * *',   -- runs every day at 9:00 AM UTC
//     $$
//       select net.http_post(
//         url := 'https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/notify-expiring-posts',
//         headers := '{"Authorization": "Bearer <YOUR_SERVICE_ROLE_KEY>"}'::jsonb
//       )
//     $$
//   );

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, // service role bypasses RLS
    );

    const now      = new Date();
    const in24hrs  = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const in48hrs  = new Date(now.getTime() + 48 * 60 * 60 * 1000);

    // Find posts expiring in the next 24 hours that are still active
    const { data: posts, error } = await supabase
      .from('posts')
      .select('id, user_id, skill_offered, title, expires_at')
      .gt('expires_at',  now.toISOString())
      .lt('expires_at',  in24hrs.toISOString())
      .eq('is_active',   true);   // only notify for still-active posts

    if (error) throw error;
    if (!posts || posts.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No expiring posts found.' }),
        { headers: { 'Content-Type': 'application/json' } },
      );
    }

    let notified = 0;

    for (const post of posts) {
      const expiresAt  = new Date(post.expires_at);
      const hoursLeft  = Math.round((expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60));
      const totalLife  = 30 * 24; // 30 days in hours (default post lifetime)
      const expiryPct  = Math.max(0, Math.min(1, hoursLeft / totalLife));
      const skillName  = post.skill_offered ?? post.title ?? 'Your post';

      // Avoid duplicate notifications — check if one was already sent
      // for this post in the last 25 hours
      const { data: existing } = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', post.user_id)
        .eq('type',    'post_expiry')
        .eq('data->>post_id', post.id)
        .gte('created_at', new Date(now.getTime() - 25 * 60 * 60 * 1000).toISOString())
        .maybeSingle();

      if (existing) continue; // already notified today, skip

      await supabase.from('notifications').insert({
        user_id:  post.user_id,
        type:     'post_expiry',
        title:    'Your post is expiring soon ⏳',
        body:     `"${skillName}" expires in ${hoursLeft} hour${hoursLeft === 1 ? '' : 's'}. Renew it to keep getting swap requests!`,
        data: {
          post_id:    post.id,
          hours_left: hoursLeft.toString(),
          expiry_pct: parseFloat(expiryPct.toFixed(2)),
          skill:      skillName,
          route:      '/my_posts',
        },
        is_read: false,
      });

      notified++;
    }

    return new Response(
      JSON.stringify({ message: `Notified ${notified} user(s).` }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error(err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});