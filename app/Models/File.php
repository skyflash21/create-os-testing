<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class File extends Model
{
    use HasFactory;

    protected $primaryKey = 'file_path';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['name', 'description',  'file_path', 'is_restricted'];

    /**
     * Relation avec le modèle FileVersion
     * Un fichier peut avoir plusieurs versions
     */
    public function versions()
    {
        return $this->hasMany(FileVersion::class, 'file_path', 'file_path');
    }

    /**
     * Permet de savoir si un fichier a été modifié.
     */
    public function isModified($hash, $version = null)
    {
        if (!$version) {
            $version = $this->versions()->orderBy('version', 'desc')->first();
        }else{
            $version = $this->versions()->where('version', $version)->first();
        }

        return $version->hash !== $hash;
    }


    /**
     * Récupération d'une version précise du fichier, si la version n'est pas spécifiée, on récupère la dernière version
     */
    public function getVersion($version = null)
    {
        if (!$version) {
            return $this->versions()->orderBy('version', 'desc')->first();
        }

        return $this->versions()->where('version', $version)->first();
    }

    /**
     * Récupération de toutes les versions du fichier
     * On récupère pour chaque version la taille et la date de création
     */
    public function getVersionsAttribute()
    {
        $versionsattribute = [];
        $versions = $this->versions()->get();
        
        foreach ($versions as $version) {
            $versionsattribute[] = [
                'version' => $version->version,
                'size' => $version->size,
                'creation_date' => $version->created_at,
            ];
        }

        return $versionsattribute;
    }

}
