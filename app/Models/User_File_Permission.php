<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class User_File_Permission extends Model
{
    use HasFactory;

    protected $fillable = [ 'user_id', 'file_id' ];
}
