<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\File;
use App\Models\FileVersion;
use Illuminate\Support\Facades\File as FileSystem;
use Illuminate\Support\Facades\DB;

class FileController extends Controller
{
    const DEFAULT_LUA_DIRECTORY = 'app\\Lua';

    /**
     * Synchroniser un répertoire de DEFAULT_LUA_DIRECTORY dans la base de données.
     * @param string $subdirectoryPath : Le chemin du répertoire à synchroniser.
     * @return array : La liste des path des fichiers synchronisés.
     */
    public function syncFolder(Request $request)
    {
        // Obtention du chemin du sous-répertoire.
        $subdirectoryPath = $request->input('path');

        if (!$subdirectoryPath) {
            return response()->json([
                'error' => 'Le chemin du répertoire est manquant.'
            ], 400);
        }

        // Obtention de tout les fichiers du répertoire (et sous-répertoires) spécifié.
        $directory = base_path(self::DEFAULT_LUA_DIRECTORY . ($subdirectoryPath ? '\\' . $subdirectoryPath : ''));
        $files = FileSystem::allFiles($directory);

        // Initialisation de la liste des fichiers ajouté.
        $syncedFiles = [];
        // Initialisation de la liste des fichiers modifiés.
        $updatedFiles = [];
        // Initialisation de la liste des fichiers non modifiés.
        $unchangedFiles = [];

        // Parcours de tout les fichiers.
        foreach ($files as $file) {
            // relative_path = chemin du fichier par rapport au répertoire de base.
            $absolutePath = $file->getRealPath();
            $relativePath = str_replace(base_path(self::DEFAULT_LUA_DIRECTORY), '', $absolutePath);

            // Syncronisation du fichier. (Appel de la fonction storeNewFile)
            $status = $this->storeNewFile($relativePath, FileSystem::get($absolutePath));

            switch ($status) {
                case 'synced':
                    $syncedFiles[] = $relativePath;
                    break;
                case 'updated':
                    $updatedFiles[] = $relativePath;
                    break;
                case 'unchanged':
                    $unchangedFiles[] = $relativePath;
                    break;
            }
        }
        
        // Retourne la liste des fichiers synchronisés.
        return response()->json([
            'syncedFiles' => $syncedFiles,
            'updatedFiles' => $updatedFiles,
            'unchangedFiles' => $unchangedFiles
        ]);
    }


    /**
     * Synchroniser un fichier de DEFAULT_LUA_DIRECTORY dans la base de données.
     * @param string $relativePath : Le chemin du fichier à synchroniser.
     * @return string : "updated", "synced" ou "unchanged" selon le cas.
     */
    public function syncFile(Request $request)
    {
        // Obtention du chemin du fichier.
        $relativePath = $request->input('path');

        if (!$relativePath) {
            return response()->json([
                'error' => 'Le chemin du fichier est manquant.'
            ], 400);
        }

        $absolutePath = base_path(self::DEFAULT_LUA_DIRECTORY . $relativePath);
        if (!FileSystem::exists($absolutePath)) {
            return response()->json([
                'error' => 'Le fichier n\'existe pas.'
            ], 404);
        }

        // Obtention du contenu du fichier.
        $content = FileSystem::get($absolutePath);

        // Synchronisation du fichier.
        $status = $this->storeNewFile($relativePath, $content);

        // Retourne le statut de la synchronisation.
        return response()->json([
            'status' => $status,
            'path' => $relativePath
        ]);
    }

    /**
     * Récupérer la denière version d'un fichier.
     */
    public function retrieveLastVersion(Request $request)
    {
        $file_path = $request->input('path');

        if (!$file_path) {
            return response()->json([
                'error' => 'Le chemin du fichier est manquant.'
            ], 400);
        }

        $file = File::where('file_path', $file_path)->first();

        if (!$file) {
            return response()->json([
                'error' => 'Le fichier n\'existe pas.'
            ], 404);
        }

        $fileVersion = $file->versions()->orderBy('version', 'desc')->first();

        return response()->json([
            'version' => $fileVersion->version
        ]);
    }

    /**
     * Récupérer la liste des fichiers stockés dans la base de données.
     */
    public function retrieveFilesList(Request $request)
    {

        $subdirectoryPath = $request->input('path') ?? '/';

        $this->syncFolderRequest($subdirectoryPath);

        $files = File::all();

        // Filtrer les fichiers par sous-répertoire.
        $files = $files->filter(function ($file) use ($subdirectoryPath) {
            return strpos($file->file_path, $subdirectoryPath) === 0;
        });

        $filesList = [];

        foreach ($files as $file) {
            $filesList[] = [
                'path' => $file->file_path,
                'last_version' => $file->versions()->orderBy('version', 'desc')->first()->version,
            ];
        }

        return response()->json($filesList);
    }

    /**
     * Récupérer toutes les versions d'un fichier avec leurs informations (creation date, size)
     */
    public function retrieveAllFileVersions(Request $request)
    {
        $file_path = $request->input('path');
        $get_raw = $request->input('raw');

        if (!$file_path) {
            return response()->json([
                'error' => 'Le chemin du fichier est manquant.'
            ], 400);
        }

        $file = File::where('file_path', $file_path)->first();

        if (!$file) {
            return response()->json([
                'error' => 'Le fichier n\'existe pas.', 'path' => $file_path
            ], 404);
        }

        if ($get_raw) {
            // return only the content as a plain text
            $versions = $file->versions()->orderBy('version', 'asc')->get(['content']);
        }

        return response()->json([
            'path' => $file->file_path,
            'versions' => $file->versions
        ]);
    }

    /**
     * Récupérer un fichier avec une version précise ou la dernière version.
     */
    public function retrieveFile(Request $request)
    {
        $file_path = $request->input('path');
        $version = $request->input('version');
        $get_raw = $request->input('raw');

        // If the file does not exist in the database, sync it
        if (!$file_path) {
            return response()->json([
                'error' => 'Le chemin du fichier est manquant.'
            ], 400);
        }

        $file = File::where('file_path', $file_path)->first();
        
        // syncFileRequest
        $this->syncFileRequest($file_path);

        if (!$file_path) {
            return response()->json([
                'error' => 'Le chemin du fichier est manquant.'
            ], 400);
        }

        $file = File::where('file_path', $file_path)->first();

        if (!$file) {
            return response()->json([
                'error' => 'Le fichier n\'existe pas.'
            ], 404);
        }

        $fileVersion = $file->getVersion($version);

        if (!$fileVersion) {
            return response()->json([
                'error' => 'La version du fichier n\'existe pas.'
            ], 404);
        }

        if ($get_raw) {
            return response($fileVersion->content)->header('Content-Type', 'text/plain');
        }

        return response()->json([
            'path' => $file->file_path,
            'version' => $fileVersion->version,
            'content' => $fileVersion->content
        ]);
    }

    /**
     * Récupérer le fichier startup en texte brut.
     */
    public function retrieveStartupFile()
    {
        $this->syncFileRequest("\Base\startup.lua");
        $fileVersion = FileVersion::where('file_path', "\Base\startup.lua")->orderBy('version', 'desc')->first();
        return response($fileVersion->content)->header('Content-Type', 'text/plain');
    }

    /**
     * Récupérer le fichier bootstrap en texte brut.
     */
    public function retrieveBootstrapFile()
    {
        $this->syncFileRequest("\Base\bootstrap.lua");
        $fileVersion = FileVersion::where('file_path', "\Base\bootstrap.lua")->orderBy('version', 'desc')->first();
        return response($fileVersion->content)->header('Content-Type', 'text/plain');
    }

    /**
     * Stocker un nouveau fichier ou une nouvelle version dans la base de données.
     */
    protected function storeNewFile(string $relativePath, string $content)
    {
        // Obtention du hash du contenu du fichier.
        $hash = hash('sha256', $content);

        // Obtention de la taille du fichier.
        $size = strlen($content);

        // Obtention du nom du fichier.
        $name = pathinfo($relativePath, PATHINFO_FILENAME);

        // Recherche du fichier dans la base de données.
        $file = File::where('file_path', $relativePath)->first();

        // Si le fichier n'existe pas dans la base de données.
        if (!$file) {
            // Création du fichier dans la base de données.
            $file = new File();
            $file->file_path = $relativePath;
            $file->name = $name;
            $file->description = null;
            $file->save();

            // Création de la première version du fichier.
            $fileVersion = new FileVersion();
            $fileVersion->file_path = $relativePath;
            $fileVersion->content = $content;
            $fileVersion->version = 1;
            $fileVersion->change_note = null;
            $fileVersion->size = $size;
            $fileVersion->hash = $hash;
            $fileVersion->save();

            return "synced";
        }

        // Recherche de la dernière version du fichier dans la base de données.
        $lastVersion = FileVersion::where('file_path', $relativePath)->orderBy('version', 'desc')->first();

        // Si le fichier n'a pas changé.
        if ($lastVersion->hash === $hash) {
            return "unchanged";
        }

        // Création d'une nouvelle version du fichier.
        $fileVersion = new FileVersion();
        $fileVersion->file_path = $relativePath;
        $fileVersion->content = $content;
        $fileVersion->version = $lastVersion->version + 1;
        $fileVersion->size = $size;
        $fileVersion->hash = $hash;
        $fileVersion->save();

        return "updated";
    }

    /**
     * Verifie si le fichier est bien le dernier disponible
     */
    protected function isLastest(string $elativePath, string $content)
    {
        // Obtention du hash du contenu du fichier.
        $hash = hash('sha256', $content);

        // Recherche du fichier dans la base de données.
        $file = File::where('file_path', $relativePath)->first();

        // Si le fichier n'existe pas dans la base de données.
        if (!$file) {
            return false;
        }

        // Recherche de la dernière version du fichier dans la base de données.
        $lastVersion = FileVersion::where('file_path', $relativePath)->orderBy('version', 'desc')->first();

        // Si le fichier n'a pas changé.
        if ($lastVersion->hash === $hash) {
            return true;
        }

        return false;
    }

    /**
     * Syncroniser un fichier avec la base de données.
     */
    protected function syncFileRequest(String $relativePath)
    {
        // Obtenir le fichier depuis le stocakge.
        $content = FileSystem::get(base_path(self::DEFAULT_LUA_DIRECTORY . $relativePath));

        // Syncroniser le fichier.
        $status = $this->storeNewFile($relativePath, $content);

        return $status;
    }

    /**
     * Syncroniser un répertoire avec la base de données.
     */
    protected function syncFolderRequest(String $subdirectoryPath)
    {
        // Obtenir le répertoire depuis le stocakge.
        $directory = base_path(self::DEFAULT_LUA_DIRECTORY . ($subdirectoryPath ? '\\' . $subdirectoryPath : ''));
        $files = FileSystem::allFiles($directory);

        // Syncroniser le répertoire.
        foreach ($files as $file) {
            $absolutePath = $file->getRealPath();
            $relativePath = str_replace(base_path(self::DEFAULT_LUA_DIRECTORY), '', $absolutePath);
            $content = FileSystem::get($absolutePath);

            $this->storeNewFile($relativePath, $content);
        }
    }
}
