<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use App\Models\File;

class FileController extends Controller
{
    const DEFAULT_LUA_DIRECTORY = 'app\\Lua\\';
    const STARTUP_FILE = 'Base\\startup.lua';
    const BOOTSTRAP_FILE = 'Base\\bootstrap.lua';

    /**
     * Récupérer un fichier dans un répertoire.
     */
    public function retrieveFile(Request $request)
    {
        $relativePath = $request->input('path', '');
        $fullPath = base_path(self::DEFAULT_LUA_DIRECTORY . $relativePath);
        $getRaw = $request->boolean('get_raw', false);
        $version = $request->input('version', null);

        $fileRecord = $this->getFileRecord($fullPath, $version);

        if (!$fileRecord) {
            if (!is_file($fullPath)) {
                return response()->json(['error' => "Le fichier $relativePath n'existe pas"], 404);
            }

            $content = $this->getFileContent($fullPath);
            $fileRecord = $this->storeNewFile($fullPath, $content);
        } else {
            $content = $this->getFileContent($fullPath);
            if ($this->hasFileChanged($content, $fileRecord->hash)) {
                $fileRecord = $this->storeNewFile($fullPath, $content, $fileRecord->version);
            }
        }

        return $getRaw ? $this->sendRawContent($content) : $this->sendFileResponse($fileRecord);
    }

    /**
     * Récupérer la version d'un fichier.
     */
    public function retrieveFileVersion(Request $request)
    {
        $relativePath = $request->input('path', '');
        $fullPath = base_path(self::DEFAULT_LUA_DIRECTORY . $relativePath);

        $fileRecord = $this->getFileRecord($fullPath);

        if (!$fileRecord) {
            if (!is_file($fullPath)) {
                return response()->json(['error' => "Le fichier $relativePath n'existe pas"], 404);
            }

            $content = $this->getFileContent($fullPath);
            $fileRecord = $this->storeNewFile($fullPath, $content);
            $fileChanged = true;
        } else {
            $content = $this->getFileContent($fullPath);
            $fileChanged = $this->hasFileChanged($content, $fileRecord->hash);

            if ($fileChanged) {
                $fileRecord = $this->storeNewFile($fullPath, $content, $fileRecord->version);
            }
        }

        return response()->json(['version' => $fileRecord->version, 'file_changed' => $fileChanged], 200);
    }

    /**
     * Récupérer la liste des fichiers dans un répertoire.
     */
    public function retrieveFilesList(Request $request)
    {
        $relativePath = $request->input('path', '');
        $fullPath = base_path(self::DEFAULT_LUA_DIRECTORY . $relativePath);

        if (!is_dir($fullPath)) {
            return response()->json(['error' => "Le répertoire $relativePath n'existe pas"], 404);
        }

        $files = array_values(array_filter(scandir($fullPath), function ($file) {
            return strpos($file, '.') !== 0;
        }));

        return response()->json(['files' => $files], 200);
    }

    /**
     * Récupérer le fichier d'installation.
     */
    public function retrieveStartupFile(Request $request)
    {
        return $this->retrieveSpecialFile(self::STARTUP_FILE);
    }

    /**
     * Récupérer le fichier de démarrage.
     */
    public function retrieveBootstrapFile(Request $request)
    {
        return $this->retrieveSpecialFile(self::BOOTSTRAP_FILE);
    }

    /**
     * Méthode privée pour traiter les fichiers spéciaux (startup/bootstrap).
     */
    private function retrieveSpecialFile(string $filePath)
    {
        $fullPath = base_path(self::DEFAULT_LUA_DIRECTORY . $filePath);

        if (!is_file($fullPath)) {
            return response()->json(['error' => "Le fichier $filePath n'existe pas"], 404);
        }

        $content = $this->getFileContent($fullPath);
        $fileRecord = $this->getFileRecord($fullPath);

        if (!$fileRecord || $this->hasFileChanged($content, $fileRecord->hash)) {
            $fileRecord = $this->storeNewFile($fullPath, $content, $fileRecord->version ?? null);
        }

        return $this->sendRawContent($content);
    }

    /**
     * Récupérer un enregistrement de fichier depuis la base de données ou le cache.
     */
    protected function getFileRecord(string $fullPath, ?int $version = null): ?File
    {
        $cacheKey = $version ? "file_record_{$fullPath}_v{$version}" : "file_record_{$fullPath}_latest";
        return Cache::remember($cacheKey, now()->addMinutes(10), function () use ($fullPath, $version) {
            $query = File::where('path', $fullPath);
            return $version ? $query->where('version', $version)->first() : $query->orderBy('version', 'desc')->first();
        });
    }

    /**
     * Récupérer et minifier le contenu d'un fichier.
     */
    protected function getFileContent(string $filePath): string
    {
        return file_get_contents($filePath);
    }

    /**
     * Vérifier si le fichier a changé.
     */
    protected function hasFileChanged(string $content, string $existingHash): bool
    {
        return hash('sha256', $content) !== $existingHash;
    }

    /**
     * Stocker un nouveau fichier dans la base de données.
     */
    protected function storeNewFile(string $filePath, string $content, ?int $currentVersion = null): File
    {
        $newVersion = $currentVersion ? $currentVersion + 1 : 1;
        $file = new File([
            'content' => $content,
            'hash' => hash('sha256', $content),
            'path' => $filePath,
            'version' => $newVersion,
            'size' => strlen($content),
            'name' => basename($filePath),
        ]);
        $file->save();

        // Mise à jour du cache
        Cache::put("file_record_{$filePath}_latest", $file, now()->addMinutes(10));
        if ($currentVersion) {
            Cache::put("file_record_{$filePath}_v{$newVersion}", $file, now()->addMinutes(10));
        }

        return $file;
    }

    /**
     * Retourner une réponse avec le fichier brut.
     */
    protected function sendRawContent(string $content)
    {
        return response($content, 200)->header('Content-Type', 'text/plain');
    }

    /**
     * Retourner une réponse JSON avec les informations du fichier.
     */
    protected function sendFileResponse(File $file)
    {
        return response()->json([
            'file' => [
                'version' => $file->version,
                'content' => $file->content
            ]
        ], 200);
    }
}
