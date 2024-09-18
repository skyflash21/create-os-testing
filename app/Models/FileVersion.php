<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FileVersion extends Model
{
    use HasFactory;

    protected $fillable = ['file_path', 'content', 'version', 'hash','size', 'change_note', 'is_restricted'];

    /**
     * Relation avec le modèle File
     * Une version de fichier appartient à un fichier
     */
    public function file()
    {
        return $this->belongsTo(File::class, 'file_path', 'file_path');
    }

    /**
     * Récupération de la taille du fichier formatée.
     */
    public function getSizeAttribute($value)
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];

        for ($i = 0; $value > 1024; $i++) {
            $value /= 1024;
        }

        return round($value, 2) . ' ' . $units[$i];
    }

    /**
     * Récupération de la date de création formatée.
     */
    public function getCreatedAtAttribute($value)
    {
        return date('d/m/Y H:i:s', strtotime($value));
    }
}
