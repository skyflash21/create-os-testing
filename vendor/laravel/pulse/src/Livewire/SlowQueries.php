<?php

namespace Laravel\Pulse\Livewire;

use Illuminate\Contracts\Support\Renderable;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\View;
use Laravel\Pulse\Recorders\Concerns\Thresholds;
use Laravel\Pulse\Recorders\SlowQueries as SlowQueriesRecorder;
use Livewire\Attributes\Lazy;
use Livewire\Attributes\Url;

/**
 * @internal
 */
#[Lazy]
class SlowQueries extends Card
{
    use Thresholds;

    /**
     * Ordering.
     *
     * @var 'slowest'|'count'
     */
    #[Url(as: 'slow-queries')]
    public string $orderBy = 'slowest';

    /**
     * Indicates that SQL highlighting should be disabled.
     */
    public bool $withoutHighlighting = false;

    /**
     * Indicates that SQL highlighting should be disabled.
     *
     * @deprecated
     */
    public bool $disableHighlighting = false;

    /**
     * Render the component.
     */
    public function render(): Renderable
    {
        [$slowQueries, $time, $runAt] = $this->remember(
            fn () => $this->aggregate(
                'slow_query',
                ['max', 'count'],
                match ($this->orderBy) {
                    'count' => 'count',
                    default => 'max',
                },
            )->map(function ($row) {
                [$sql, $location] = json_decode($row->key, flags: JSON_THROW_ON_ERROR);

                return (object) [
                    'sql' => $sql,
                    'location' => $location,
                    'slowest' => $row->max,
                    'count' => $row->count,
                    'threshold' => $this->threshold($sql, SlowQueriesRecorder::class),
                ];
            }),
            $this->orderBy,
        );

        return View::make('pulse::livewire.slow-queries', [
            'time' => $time,
            'runAt' => $runAt,
            'config' => Config::get('pulse.recorders.'.SlowQueriesRecorder::class),
            'slowQueries' => $slowQueries,
        ]);
    }

    /**
     * Determine if the view should highlight SQL queries.
     */
    protected function wantsHighlighting(): bool
    {
        return ! ($this->withoutHighlighting || $this->disableHighlighting);
    }
}
