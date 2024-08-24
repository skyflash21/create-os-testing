<?php

namespace Laravel\Pulse\Livewire;

use Carbon\CarbonImmutable;
use Carbon\CarbonInterval;
use Illuminate\Contracts\Support\Renderable;
use Illuminate\Support\Facades\View;
use Illuminate\Support\InteractsWithTime;
use Livewire\Attributes\Lazy;
use Livewire\Livewire;

/**
 * @internal
 */
#[Lazy]
class Servers extends Card
{
    use InteractsWithTime;

    public int|string|null $ignoreAfter = null;

    /**
     * Render the component.
     */
    public function render(): Renderable
    {
        [$servers, $time, $runAt] = $this->remember(function () {
            $graphs = $this->graph(['cpu', 'memory'], 'avg');

            return $this->values('system')
                ->map(function ($system, $slug) use ($graphs) {
                    if ($this->ignoreSystem($system)) {
                        return null;
                    }

                    $values = json_decode($system->value, flags: JSON_THROW_ON_ERROR);

                    return (object) [
                        'name' => (string) $values->name,
                        'cpu_current' => (int) $values->cpu,
                        'cpu' => $graphs->get($slug)?->get('cpu') ?? collect(),
                        'memory_current' => (int) $values->memory_used,
                        'memory_total' => (int) $values->memory_total,
                        'memory' => $graphs->get($slug)?->get('memory') ?? collect(),
                        'storage' => collect($values->storage), // @phpstan-ignore argument.templateType, argument.templateType
                        'updated_at' => $updatedAt = CarbonImmutable::createFromTimestamp($system->timestamp),
                        'recently_reported' => $updatedAt->isAfter(now()->subSeconds(30)),
                    ];
                })
                ->filter()
                ->sortBy('name');
        });

        if (Livewire::isLivewireRequest()) {
            $this->dispatch('servers-chart-update', servers: $servers);
        }

        return View::make('pulse::livewire.servers', [
            'servers' => $servers,
            'time' => $time,
            'runAt' => $runAt,
        ]);
    }

    /**
     * Render the placeholder.
     */
    public function placeholder(): Renderable
    {
        return View::make('pulse::components.servers-placeholder', ['cols' => $this->cols, 'rows' => $this->rows, 'class' => $this->class]);
    }

    /**
     * Determine if the system should be ignored.
     *
     * @param  object{ timestamp: int, key: string, value: string }  $system
     */
    protected function ignoreSystem(object $system): bool
    {
        if ($this->ignoreAfter === null) {
            return false;
        }

        $ignoreAfter = is_numeric($this->ignoreAfter)
            ? (int) $this->ignoreAfter
            : CarbonInterval::createFromDateString($this->ignoreAfter)->totalSeconds;

        return CarbonImmutable::createFromTimestamp($system->timestamp)->addSeconds($ignoreAfter)->isPast();
    }
}
