<?php

use Illuminate\Support\Facades\Broadcast;
use App\Models\User;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

 
broadcast::channel('presence', function (User $user) {
    return ['id' => $user->id, 'name' => $user->name, 'profile_photo_url' => $user->profile_photo_url];
});
 
Broadcast::channel('computer.{roomId}', function (User $user) {
    $user->isUser = true;
    $user->id = -1;
    return $user;
});