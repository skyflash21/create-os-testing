<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use App\Models\File;
use App\Models\FileVersion;
use Illuminate\Support\Facades\File as FileSystem; // Utilisé pour scanner les fichiers du répertoire

class FileController extends Controller
{
    const DEFAULT_LUA_DIRECTORY = 'app/Lua/';

    /**
     * Synchroniser les fichiers de DEFAULT_LUA_DIRECTORY dans la base de données.
     */
    public function syncFile()
    {
        // Scan tout les fichiers dans le répertoire DEFAULT_LUA_DIRECTORY
        $directoryPath = str_replace('//', '/', str_replace('\\', '/', base_path(self::DEFAULT_LUA_DIRECTORY)));
        $files = FileSystem::allFiles($directoryPath);

        $filesList = [];
    
        foreach ($files as $file) {
            // Suppression du chemin de base E:/Programmation/Workspaces/Laravel/craft-os/app/Lua/ pour ne garder que Base/bootstrap.lua
            
            $filePath = str_replace($directoryPath, '', str_replace('//', '/', str_replace('\\', '/', $file->getPathname())));
    
            $content = FileSystem::get($file->getPathname());
    
            // Récupérer l'enregistrement de fichier dans la base de données
            $fileRecord = File::where('path', $filePath)->first();
    
            if (!$fileRecord) {
                // Nouveau fichier, on l'ajoute à la base
                $this->storeNewFile($filePath, $content);
            } else {
                // Vérifier si le fichier a changé
                if ($this->hasFileChanged($content, $fileRecord->hash)) {
                    // Le fichier a changé, on ajoute une nouvelle version
                    $this->storeNewFile($filePath, $content, $fileRecord->versions->last()->version);
                }
            }
        }
    }
    
    /**
     * Récupérer la liste des fichiers stockés dans la base de données.
     */
    public function retrieveFilesList(Request $request)
    {
        $path = $request->input('path', '');

        if ($path) {
            $files = File::where('path', 'like', "$path%")->get();
        } else {
            return response()->json(['error' => 'Le paramètre path est obligatoire'], 400);
        }

        // Liste tout les fichiers qui on pour début de chemin le paramètre path
        $filesList = [];
        foreach ($files as $file) {
            $filesList[] = $file->path;
        }

        return response()->json(['files' => $filesList], 200);
    }

    /**
     * Récupérer un fichier depuis la base de données.
     */
    public function retrieveFile(Request $request)
    {
        $relativePath = $request->input('path', '');
        $version = $request->input('version', null);
        $get_raw = $request->input('get_raw', false);

        $fileRecord = File::where('path', $relativePath)->first();

        if (!$fileRecord) {
            return response()->json(['error' => "Le fichier $relativePath n'existe pas"], 404);
        }

        $fileVersion = $version
            ? FileVersion::where('file_path', $fileRecord->path)->where('version', $version)->first()
            : $fileRecord->versions->last();

        if (!$fileVersion) {
            return response()->json(['error' => "La version $version n'existe pas"], 404);
        }

        // Retourner le contenu brut du fichier
        if ($get_raw) {
            return response($fileVersion->content, 200)
                ->header('Content-Type', 'text/plain');
        }

        return $this->sendFileResponse($fileVersion);
    }

    /**
     * Récupérer la version d'un fichier depuis la base de données.
     */
    public function retrieveFileVersion(Request $request)
    {

        $relativePath = $request->input('path', '');

        $fileRecord = File::where('path', $relativePath)->first();

        if (!$fileRecord) {
            return response()->json(['error' => "Le fichier $relativePath n'existe pas"], 404);
        }

        return response()->json(['version' => $fileRecord->versions->last()->version], 200);
    }

    /**
     * Vérifier si le fichier a changé.
     */
    protected function hasFileChanged(string $content, string $existingHash): bool
    {
        return hash('sha256', $content) !== $existingHash;
    }

    /**
     * Stocker un nouveau fichier ou une nouvelle version dans la base de données.
     */
    protected function storeNewFile(string $filePath, string $content, ?int $currentVersion = null): File
    {
        // Si le fichier n'existe pas, on le crée
        $fileRecord = File::firstOrCreate(
            ['path' => $filePath],
            [
                'name' => basename($filePath),
                'description' => null,
                'size' => strlen($content),
                'hash' => hash('sha256', $content)
            ]
        );

        // Créer une nouvelle version pour ce fichier
        $newVersion = $currentVersion ? $currentVersion + 1 : 1;
        $fileVersion = new FileVersion([
            'file_path' => $fileRecord->path,
            'content' => $content,
            'version' => $newVersion,
            'hash' => hash('sha256', $content)
        ]);
        $fileVersion->save();

        // Mise à jour du cache
        Cache::put("file_record_{$filePath}_latest", $fileVersion, now()->addMinutes(10));
        if ($currentVersion) {
            Cache::put("file_record_{$filePath}_v{$newVersion}", $fileVersion, now()->addMinutes(10));
        }

        return $fileRecord;
    }

    /**
     * Retourner une réponse JSON avec les informations de la version du fichier.
     */
    protected function sendFileResponse(FileVersion $fileVersion)
    {
        return response()->json([
            'file' => [
                'version' => $fileVersion->version,
                'content' => $fileVersion->content
            ]
        ], 200);
    }

    /**
     * Récupérer le fichier startup
     */
    public function retrieveStartupFile()
    {
        // synchroniser les fichiers
        $this->syncFile();
        
        $fileRecord = File::where('path', 'Base/startup.lua')->first();

        if (!$fileRecord) {
            return response()->json(['error' => "Le fichier startup.lua n'existe pas"], 404);
        }

        $fileVersion = $fileRecord->versions->last();

        //return the raw content of the file.
        $file_to_return = $this->sendFileResponse($fileVersion);
        return $file_to_return->original['file']['content'];
    }

    /**
     * Récupérer le fichier bootstrap
     */
    public function retrieveBootstrapFile()
    {
        // Récupération de la dernière version du fichier bootstrap.lua
        $fileRecord = File::where('path', 'Base/bootstrap.lua')->first();

        if (!$fileRecord) {
            return response()->json(['error' => "Le fichier bootstrap.lua n'existe pas"], 404);
        }

        $fileVersion = $fileRecord->versions->last();

        //return the raw content of the file.
        $file_to_return = $this->sendFileResponse($fileVersion);
        return $file_to_return->original['file']['content'];
    }
}
