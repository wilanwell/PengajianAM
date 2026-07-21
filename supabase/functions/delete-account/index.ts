import {
  createClient,
} from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, '
    + 'apikey, content-type',
  'Access-Control-Allow-Methods':
    'POST, OPTIONS',
}

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(
    JSON.stringify(body),
    {
      status,
      headers: {
        ...corsHeaders,
        'Content-Type':
          'application/json; charset=utf-8',
      },
    },
  )
}

function readProjectKey(
  jsonEnvironmentName: string,
  legacyEnvironmentName: string,
): string | null {
  const jsonValue =
    Deno.env.get(jsonEnvironmentName)

  if (jsonValue != null) {
    try {
      const parsed = JSON.parse(
        jsonValue,
      ) as Record<string, unknown>

      const defaultValue =
        parsed.default

      if (
        typeof defaultValue === 'string'
        && defaultValue.trim().length > 0
      ) {
        return defaultValue.trim()
      }

      for (
        const value
        of Object.values(parsed)
      ) {
        if (
          typeof value === 'string'
          && value.trim().length > 0
        ) {
          return value.trim()
        }
      }
    } catch {
      /*
       * Jangan log kandungan environment
       * variable kerana ia mungkin
       * mengandungi secret key.
       */
    }
  }

  const legacyValue =
    Deno.env.get(legacyEnvironmentName)

  if (
    legacyValue == null
    || legacyValue.trim().length === 0
  ) {
    return null
  }

  return legacyValue.trim()
}

Deno.serve(
  async (
    request: Request,
  ): Promise<Response> => {
    if (request.method === 'OPTIONS') {
      return new Response(
        'ok',
        {
          headers: corsHeaders,
        },
      )
    }

    if (request.method !== 'POST') {
      return jsonResponse(
        {
          success: false,
          message:
            'Kaedah permintaan tidak dibenarkan.',
        },
        405,
      )
    }

    const authorizationHeader =
      request.headers.get(
        'Authorization',
      )

    if (
      authorizationHeader == null
      || !authorizationHeader.startsWith(
        'Bearer ',
      )
    ) {
      return jsonResponse(
        {
          success: false,
          message:
            'Authentication diperlukan.',
        },
        401,
      )
    }

    const supabaseUrl =
      Deno.env.get('SUPABASE_URL')

    const publishableKey =
      readProjectKey(
        'SUPABASE_PUBLISHABLE_KEYS',
        'SUPABASE_ANON_KEY',
      )

    const secretKey =
      readProjectKey(
        'SUPABASE_SECRET_KEYS',
        'SUPABASE_SERVICE_ROLE_KEY',
      )

    if (
      supabaseUrl == null
      || publishableKey == null
      || secretKey == null
    ) {
      console.error(
        'Supabase Edge Function '
        + 'environment is incomplete.',
      )

      return jsonResponse(
        {
          success: false,
          message:
            'Konfigurasi server tidak lengkap.',
        },
        500,
      )
    }

    /*
     * Client pengguna menggunakan JWT
     * daripada Authorization header.
     *
     * Client ini hanya digunakan untuk
     * menentukan identiti sebenar pemanggil.
     */
    const userClient = createClient(
      supabaseUrl,
      publishableKey,
      {
        global: {
          headers: {
            Authorization:
              authorizationHeader,
          },
        },
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    )

    const {
      data: userData,
      error: userError,
    } = await userClient.auth.getUser()

    const user = userData.user

    if (
      userError != null
      || user == null
    ) {
      console.error(
        'Delete account user '
        + 'verification failed:',
        userError?.message,
      )

      return jsonResponse(
        {
          success: false,
          message:
            'Sesi pengguna tidak sah '
            + 'atau telah tamat.',
        },
        401,
      )
    }

    /*
     * Client admin hanya wujud di server.
     *
     * Secret key tidak pernah dihantar
     * kepada aplikasi Flutter.
     */
    const adminClient = createClient(
      supabaseUrl,
      secretKey,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    )

    const {
      error: deleteError,
    } = await adminClient.auth.admin
      .deleteUser(
        user.id,
        false,
      )

    if (deleteError != null) {
      console.error(
        'Delete account failed:',
        deleteError.message,
      )

      return jsonResponse(
        {
          success: false,
          message:
            'Akaun tidak dapat dipadamkan. '
            + 'Sila cuba semula.',
        },
        500,
      )
    }

    return jsonResponse(
      {
        success: true,
        message:
          'Akaun telah dipadamkan.',
      },
    )
  },
)