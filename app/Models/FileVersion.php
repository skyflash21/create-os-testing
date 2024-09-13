<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FileVersion extends Model
{
    use HasFactory;

    protected $fillable = ['file_path', 'content', 'version'];

    /**
     * Relation avec le modèle File
     * Une version de fichier appartient à un fichier
     */
    public function file()
    {
        return $this->belongsTo(File::class, 'file_path', 'path');
    }
}
