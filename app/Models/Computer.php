<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Laravel\Sanctum\PersonalAccessToken; // Import the Sanctum PersonalAccessToken class

class Computer extends Model
{
    use HasFactory;

    protected $fillable = ['personal_access_token_id'];

    public function personalAccessToken()
    {
        return $this->belongsTo(PersonalAccessToken::class);
    }
}
