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

type JsonObject = Record<string, unknown>

type AuthenticationFailure = {
  status: number
  message: string
}

function isJsonObject(
  value: unknown,
): value is JsonObject {
  return (
    typeof value === 'object'
    && value !== null
    && !Array.isArray(value)
  )
}

function jsonResponse(
  body: JsonObject,
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
  fallbackEnvironmentNames: string[],
): string | null {
  const jsonValue =
    Deno.env.get(jsonEnvironmentName)

  if (jsonValue != null) {
    try {
      const parsed =
        JSON.parse(jsonValue)

      if (isJsonObject(parsed)) {
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
      }
    } catch {
      /*
       * Jangan log environment variable.
       * Ia mungkin mengandungi secret.
       */
    }
  }

  for (
    const environmentName
    of fallbackEnvironmentNames
  ) {
    const value =
      Deno.env.get(environmentName)

    if (
      value != null
      && value.trim().length > 0
    ) {
      return value.trim()
    }
  }

  return null
}

function mapPasswordVerificationFailure(
  originalMessage: string,
): AuthenticationFailure {
  const message =
    originalMessage.toLowerCase()

  if (
    message.includes(
      'invalid login credentials',
    )
    || message.includes(
      'invalid email or password',
    )
    || message.includes(
      'email not confirmed',
    )
  ) {
    return {
      status: 403,
      message:
        'Kata laluan semasa tidak betul.',
    }
  }

  if (
    message.includes('rate limit')
    || message.includes(
      'too many requests',
    )
    || message.includes(
      'for security purposes',
    )
  ) {
    return {
      status: 429,
      message:
        'Terlalu banyak percubaan '
        + 'pengesahan. Sila tunggu '
        + 'sebentar dan cuba semula.',
    }
  }

  return {
    status: 500,
    message:
      'Identiti pengguna tidak dapat '
      + 'disahkan sekarang. '
      + 'Sila cuba semula.',
  }
}

async function readRequestPassword(
  request: Request,
): Promise<
  | {
      password: string
      error: null
    }
  | {
      password: null
      error: Response
    }
> {
  let payload: unknown

  try {
    payload = await request.json()
  } catch {
    return {
      password: null,
      error: jsonResponse(
        {
          success: false,
          message:
            'Body permintaan tidak sah.',
        },
        400,
      ),
    }
  }

  if (!isJsonObject(payload)) {
    return {
      password: null,
      error: jsonResponse(
        {
          success: false,
          message:
            'Body permintaan tidak sah.',
        },
        400,
      ),
    }
  }

  const currentPassword =
    payload.currentPassword

  if (
    typeof currentPassword !== 'string'
    || currentPassword.length === 0
  ) {
    return {
      password: null,
      error: jsonResponse(
        {
          success: false,
          message:
            'Masukkan kata laluan semasa.',
        },
        400,
      ),
    }
  }

  /*
   * Had ini mengelakkan body luar biasa besar.
   *
   * Jangan trim kata laluan kerana space
   * mungkin merupakan sebahagian daripadanya.
   */
  if (currentPassword.length > 1024) {
    return {
      password: null,
      error: jsonResponse(
        {
          success: false,
          message:
            'Kata laluan semasa tidak sah.',
        },
        400,
      ),
    }
  }

  return {
    password: currentPassword,
    error: null,
  }
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
            'Kaedah permintaan '
            + 'tidak dibenarkan.',
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

    const passwordResult =
      await readRequestPassword(request)

    if (passwordResult.error != null) {
      return passwordResult.error
    }

    const currentPassword =
      passwordResult.password

    const supabaseUrl =
      Deno.env.get('SUPABASE_URL')

    const publishableKey =
      readProjectKey(
        'SUPABASE_PUBLISHABLE_KEYS',
        [
          'SUPABASE_PUBLISHABLE_KEY',
          'SUPABASE_ANON_KEY',
        ],
      )

    const secretKey =
      readProjectKey(
        'SUPABASE_SECRET_KEYS',
        [
          'SUPABASE_SECRET_KEY',
          'SUPABASE_SERVICE_ROLE_KEY',
        ],
      )

    if (
      supabaseUrl == null
      || publishableKey == null
      || secretKey == null
    ) {
      console.error(
        'Delete-account server '
        + 'configuration is incomplete.',
      )

      return jsonResponse(
        {
          success: false,
          message:
            'Konfigurasi server '
            + 'tidak lengkap.',
        },
        500,
      )
    }

    /*
     * Client pertama menggunakan JWT pemanggil.
     *
     * Tujuannya ialah mendapatkan identiti
     * sebenar pemilik access token.
     */
    const callerClient = createClient(
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
          detectSessionInUrl: false,
        },
      },
    )

    const {
      data: callerData,
      error: callerError,
    } = await callerClient.auth.getUser()

    const callerUser =
      callerData.user

    if (
      callerError != null
      || callerUser == null
    ) {
      console.error(
        'Delete-account caller '
        + 'verification failed.',
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

    const callerEmail =
      callerUser.email?.trim()

    if (
      callerEmail == null
      || callerEmail.length === 0
    ) {
      return jsonResponse(
        {
          success: false,
          message:
            'Alamat e-mel akaun '
            + 'tidak tersedia.',
        },
        409,
      )
    }

    /*
     * Client kedua tidak menggunakan session
     * pemanggil.
     *
     * Ia menjalankan authentication baharu
     * menggunakan e-mel akaun daripada JWT
     * dan kata laluan yang diterima.
     *
     * Ini menjadikan semakan kata laluan
     * berlaku pada server, bukan sekadar
     * pada Flutter.
     */
    const verificationClient =
      createClient(
        supabaseUrl,
        publishableKey,
        {
          auth: {
            persistSession: false,
            autoRefreshToken: false,
            detectSessionInUrl: false,
          },
        },
      )

    const {
      data: verificationData,
      error: verificationError,
    } = await verificationClient.auth
      .signInWithPassword(
        {
          email: callerEmail,
          password: currentPassword,
        },
      )

    if (verificationError != null) {
      const failure =
        mapPasswordVerificationFailure(
          verificationError.message,
        )

      console.error(
        'Delete-account password '
        + 'verification failed.',
      )

      return jsonResponse(
        {
          success: false,
          message: failure.message,
        },
        failure.status,
      )
    }

    const verifiedUser =
      verificationData.user

    const verifiedSession =
      verificationData.session

    if (
      verifiedUser == null
      || verifiedSession == null
      || verifiedUser.id !== callerUser.id
    ) {
      console.error(
        'Delete-account verified '
        + 'identity did not match caller.',
      )

      return jsonResponse(
        {
          success: false,
          message:
            'Pengesahan identiti gagal.',
        },
        403,
      )
    }

    /*
     * Client admin hanya menggunakan secret
     * key pada server.
     *
     * Secret tidak pernah dihantar kepada
     * aplikasi Flutter.
     */
    const adminClient = createClient(
      supabaseUrl,
      secretKey,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
          detectSessionInUrl: false,
        },
      },
    )

    const {
      error: deleteError,
    } = await adminClient.auth.admin
      .deleteUser(
        callerUser.id,
        false,
      )

    if (deleteError != null) {
      console.error(
        'Delete-account admin '
        + 'deletion failed.',
      )

      return jsonResponse(
        {
          success: false,
          message:
            'Akaun tidak dapat '
            + 'dipadamkan. '
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