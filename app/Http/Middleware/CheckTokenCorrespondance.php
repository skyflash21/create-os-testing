<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Laravel\Sanctum\PersonalAccessToken;
use App\Models\Computer;

class CheckTokenCorrespondance
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     * @return \Symfony\Component\HttpFoundation\Response
     */
    public function handle(Request $request, Closure $next): Response
    {

        // Retrieve the computer_id from the request headers
        $computer_id = $request->computer_id ?? $request->route('computer_id');

        if (!$computer_id) {
            return response()-> json(['message' => 'Computer ID not found'], 401);
        }

        // Retrieve the computer from the request body (computer_id)
        $computer = Computer::find( $computer_id);

        // If the computer doesn't exist, return unauthorized
        if (!$computer) {
            return response()->json(['message' => 'Computer not found ' .  $computer_id], 401);
        }

        // Retrieve the personal access token associated with the computer
        $personalAccessToken = PersonalAccessToken::find($computer->personal_access_token_id);

        // If there is no token or the tokens don't match, return unauthorized
        if (!$personalAccessToken || !hash_equals($personalAccessToken->token, hash('sha256', $request->bearerToken()))) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        return $next($request);
    }
}
