<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

use App\Models\User;
 
broadcast::channel('presence', function (User $user) {
    return ['id' => $user->id, 'name' => $user->name, 'profile_photo_url' => $user->profile_photo_url];
});