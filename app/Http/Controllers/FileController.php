<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use App\Models\File;
use App\Models\FileVersion;
use Illuminate\Support\Facades\File as FileSystem;

class FileController extends Controller
{
    const DEFAULT_LUA_DIRECTORY = 'app/Lua/';

    /**
     * Synchroniser les fichiers de DEFAULT_LUA_DIRECTORY dans la base de données.
     */
    public function syncFile()
    {
        // Chemin absolu vers le répertoire Lua
        $directoryPath = realpath(base_path(self::DEFAULT_LUA_DIRECTORY));
        $files = FileSystem::allFiles($directoryPath);

        $createdFiles = [];
        $modifiedFiles = [];

        foreach ($files as $file) {
            // Convertir le chemin absolu en chemin relatif à partir de Lua
            $absoluteFilePath = $file->getPathname();
            $relativeFilePath = ltrim(str_replace($directoryPath, '', $absoluteFilePath), DIRECTORY_SEPARATOR);

            // Maintenant, $relativeFilePath contient par exemple 'Components/api.lua'
            $content = FileSystem::get($absoluteFilePath);

            // Replace all \ with / $relativeFilePath
            $relativeFilePath = str_replace('\\', '/', $relativeFilePath);

            // Utilisation du cache pour améliorer les performances
            $fileRecord = Cache::remember("file_record_{$relativeFilePath}_latest", 10, function () use ($relativeFilePath) {
                return FileVersion::where('file_path', $relativeFilePath)->latest('version')->first();
            });

            if (!$fileRecord) {
                $this->storeNewFile($relativeFilePath, $content);
                $createdFiles[] = $relativeFilePath;
            } elseif ($this->hasFileChanged($content, $fileRecord->hash)) {
                $this->storeNewFile($relativeFilePath, $content, $fileRecord->version);
                $modifiedFiles[] = $relativeFilePath;
            }
        }

        return response()->json(['modified_files' => $modifiedFiles, 'created_files' => $createdFiles], 200);
    }



    /**
     * Récupérer la liste des fichiers stockés dans la base de données.
     */
    public function retrieveFilesList(Request $request)
    {
        $path = $request->input('path', '');

        if (empty($path)) {
            return response()->json(['error' => 'Le paramètre path est obligatoire'], 400);
        }

        $files = File::where('path', 'like', "$path%")->pluck('path');

        return response()->json(['files' => $files], 200);
    }

    /**
     * Récupérer un fichier depuis la base de données.
     */
    public function retrieveFile(Request $request)
    {
        $relativePath = $request->input('path', '');
        $version = $request->input('version', null);
        $get_raw = $request->input('get_raw', false);

        $fileVersion = $this->getFileVersion($relativePath, $version);
        if (!$fileVersion) {
            return response()->json(['error' => "Le fichier ou la version spécifiée n'existe pas"], 404);
        }

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

        $fileVersion = $this->getFileVersion($relativePath);
        if (!$fileVersion) {
            return response()->json(['error' => "Le fichier $relativePath n'existe pas"], 404);
        }

        return response()->json(['version' => $fileVersion->version], 200);
    }

    /**
     * Récupérer la version d'un fichier depuis la base ou le cache.
     */
    protected function getFileVersion(string $relativePath, ?int $version = null)
    {
        $fileRecord = Cache::remember("file_record_{$relativePath}", 10, function () use ($relativePath) {
            return File::where('path', $relativePath)->first();
        });

        if (!$fileRecord) {
            return null;
        }

        return $version
            ? FileVersion::where('file_path', $fileRecord->path)->where('version', $version)->first()
            : $fileRecord->versions->last();
    }

    /**
     * Vérifier si le fichier a changé.
     */
    protected function hasFileChanged(string $content, string $existingHash): bool
    {
        return hash('md5', $content) !== $existingHash;
    }

    /**
     * Stocker un nouveau fichier ou une nouvelle version dans la base de données.
     */
    protected function storeNewFile(string $filePath, string $content, ?int $currentVersion = null): File
    {
        $fileRecord = File::firstOrCreate(
            ['path' => $filePath],
            ['name' => basename($filePath)]
        );

        $newVersion = $currentVersion ? $currentVersion + 1 : 1;
        $fileVersion = new FileVersion([
            'file_path' => $fileRecord->path,
            'content' => $content,
            'version' => $newVersion,
            'size' => strlen($content),
            'hash' => hash('md5', $content)
        ]);
        $fileVersion->save();

        Cache::put("file_record_{$filePath}_latest", $fileVersion, now()->addMinutes(10));

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
        return $this->retrieveSpecificFile('Base/startup.lua');
    }

    /**
     * Récupérer le fichier bootstrap
     */
    public function retrieveBootstrapFile()
    {
        return $this->retrieveSpecificFile('Base/bootstrap.lua');
    }

    /**
     * Récupérer un fichier spécifique.
     */
    protected function retrieveSpecificFile(string $filePath)
    {
        $fileRecord = FileVersion::where('file_path', $filePath)->latest('version')->first();
        if (!$fileRecord) {
            return response()->json(['error' => "Le fichier $filePath n'existe pas"], 404);
        }
        
        //return raw 
        return response($fileRecord->content, 200)
            ->header('Content-Type', 'text/plain');
    }

    public function test_file()
    {
        // Le code Lua que vous voulez minifier
        $luaCode = 'a = ((1 + 2) - 3) * (4 / (5 ^ 6))';

        // Créer la commande luamin avec le code Lua à minifier
        // Notez que nous échappons le code Lua pour éviter les problèmes de sécurité
        $command = 'luamin -c ' . escapeshellarg($luaCode);

        // Exécuter la commande via shell_exec ou exec
        $output = shell_exec($command);

        // Afficher le résultat minifié
        echo $output;
    }
}
