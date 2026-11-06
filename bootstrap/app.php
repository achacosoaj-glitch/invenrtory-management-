<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (ValidationException $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return response()->json([
                'message' => 'The given data was invalid.',
                'errors' => $exception->errors(),
            ], 422);
        });

        $exceptions->render(function (QueryException $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            report($exception);

            $sqlState = (string) ($exception->errorInfo[0] ?? $exception->getCode());
            if ($sqlState === '45000') {
                $databaseMessage = (string) ($exception->errorInfo[2] ?? '');
                preg_match('/^(?:1644\s+)?([^\r\n]+?)(?:\s+at\s+line\s+\d+)?$/i', $databaseMessage, $matches);

                return response()->json([
                    'message' => $matches[1] ?? 'The database rejected the operation because of a business rule.',
                ], 422);
            }

            if ($sqlState === '23000') {
                return response()->json([
                    'message' => 'The operation conflicts with existing database records.',
                ], 409);
            }

            return response()->json([
                'message' => 'A database error prevented the operation.',
            ], 500);
        });
    })->create();
