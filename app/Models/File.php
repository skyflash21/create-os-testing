<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class File extends Model
{
    use HasFactory;

    protected $primaryKey = 'path';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['name', 'description',  'path'];

    /**
     * Relation avec le modèle FileVersion
     * Un fichier peut avoir plusieurs versions
     */
    public function versions()
    {
        return $this->hasMany(FileVersion::class, 'file_path', 'path');
    }
}
