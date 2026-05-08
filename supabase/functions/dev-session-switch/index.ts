// Fix #2184 (Batch 9): migrate to minglitEdgeFunction wrapper — public caller, dev-only
import { successResponse, errorResponse } from '../_shared/response_utils.ts'
import { minglitEdgeFunction, type EFContext } from '../_shared/edge_function.ts'

export const handler = async (_req: Request, ctx: EFContext): Promise<Response> => {
  const { data, error } = await ctx.supabase
    .from('user_profiles')
    .select('id, name, username')
    .order('username', { ascending: true })

  if (error) {
    return errorResponse(error.message, 500)
  }

  return successResponse({ users: data })
}

minglitEdgeFunction(handler)
