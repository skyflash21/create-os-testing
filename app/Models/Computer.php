<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Laravel\Sanctum\PersonalAccessToken;

class Computer extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'id',
        'name',
        'description',
        'personal_access_token_id',
        'type',
        'is_advanced',
        'wireless_modem_side',
        'last_used_at',
        'used_disk_space',
        'total_disk_space',
    ];

    /**
     * Get the personal access token associated with the computer.
     */
    public function personalAccessToken()
    {
        return $this->belongsTo(PersonalAccessToken::class);
    }
}
