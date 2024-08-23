<?php

namespace App\Actions\Fortify;

use App\Models\User;
use Illuminate\Support\Facades\Validator;
use Laravel\Fortify\Contracts\UpdatesUserProfileInformation;
use Illuminate\Validation\ValidationException;

class UpdateUserProfileInformation implements UpdatesUserProfileInformation
{
    /**
     * Validate and update the given user's profile information.
     *
     * @param  array<string, mixed>  $input
     */
    public function update($user, array $input)
    {
        Validator::make($input, [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email,' . $user->id],
        ])->validateWithBag('updateProfileInformation');

        if ($user->name !== $input['name']) {
            // Vérifie si la dernière mise à jour du nom a eu lieu il y a moins de 24 heures
            if ($user->name_updated_at && (strtotime($user->name_updated_at) > strtotime('-1 day'))) {
                // Calculer le temps restant
                $timeRemaining = strtotime($user->name_updated_at) - strtotime('-1 day');
                $formattedTime = $this->formatRemainingTime($timeRemaining);

                throw ValidationException::withMessages([
                    'name' => "Vous ne pouvez modifier votre nom qu'une seule fois par jour.<br>" . $formattedTime . ' restant.',
                ])->errorBag('updateProfileInformation');
            }

            $user->forceFill([
                'name' => $input['name'],
                'name_updated_at' => now(),
            ])->save();
        }

        if ($user->email !== $input['email']) {
            $user->forceFill([
                'email' => $input['email'],
            ])->save();
        }
    }

    /**
     * Format remaining time to human readable format.
     *
     * @param mixed $time
     * @return string
     */
    private function formatRemainingTime($time)
    {
        $hours = floor($time / 3600);
        $minutes = floor(($time % 3600) / 60);
        $seconds = $time % 60;

        $formattedTime = '';
        if ($hours > 0) {
            $formattedTime .= $hours . ' heure' . ($hours > 1 ? 's' : '') . ' ';
        }
        if ($minutes > 0) {
            $formattedTime .= $minutes . ' minute' . ($minutes > 1 ? 's' : '') . ' ';
        }
        if ($seconds > 0 || $formattedTime === '') {
            $formattedTime .= $seconds . ' seconde' . ($seconds > 1 ? 's' : '');
        }

        return trim($formattedTime);
    }

    /**
     * Update the given verified user's profile information.
     *
     * @param  array<string, string>  $input
     */
    protected function updateVerifiedUser(User $user, array $input): void
    {
        $user->forceFill([
            'name' => $input['name'],
            'email' => $input['email'],
            'email_verified_at' => null,
        ])->save();

        $user->sendEmailVerificationNotification();
    }
}
