<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Files extends Model
{
    use HasFactory;

    // Ajout des attributs protégés si nécessaire
    protected $fillable = ['content', 'version', 'hash', 'path', 'size', 'name'];

}
