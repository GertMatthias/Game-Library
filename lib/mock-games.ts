import type { Game, Status } from './models';

const records: [string, string, string, string[], string, Status, number, string, string, string][] = [
  ['elden-ring', 'Elden Ring', 'The Lands Between await.', ['RPG', 'Adventure'], 'PC', 'In progress', 124, '2022-02-25', '#b99b43', '✦'],
  ['hollow-knight', 'Hollow Knight', 'Beneath the surface, a kingdom sleeps.', ['Metroidvania', 'Adventure'], 'Switch', 'Completed', 48, '2017-02-24', '#739ab9', '♜'],
  ['hades', 'Hades', 'One more escape from the underworld.', ['Roguelike', 'Action'], 'PC', 'In progress', 67, '2020-09-17', '#d95a4c', '◆'],
  ['stardew-valley', 'Stardew Valley', 'A little land. A new beginning.', ['Simulation', 'RPG'], 'Switch', 'In progress', 92, '2016-02-26', '#75a56a', '❋'],
  ['celeste', 'Celeste', 'Find your way to the summit.', ['Platformer', 'Adventure'], 'PC', 'Completed', 18, '2018-01-25', '#c181b1', '△'],
  ['cyberpunk-2077', 'Cyberpunk 2077', 'Make your mark on Night City.', ['RPG', 'Action'], 'PC', 'Not played', 0, '2020-12-10', '#d2b549', '◈'],
  ['disco-elysium', 'Disco Elysium', 'A city of questions. A mind of possibilities.', ['RPG', 'Adventure'], 'PC', 'Completed', 36, '2019-10-15', '#c38966', '◉'],
  ['outer-wilds', 'Outer Wilds', 'A small solar system. An endless mystery.', ['Adventure', 'Puzzle'], 'PlayStation', 'Not played', 0, '2019-05-28', '#569c9d', '◎'],
  ['portal-2', 'Portal 2', 'Think outside the test chamber.', ['Puzzle', 'Adventure'], 'PC', 'Completed', 14, '2011-04-19', '#4f9aca', '◐'],
  ['doom-eternal', 'DOOM Eternal', 'Keep moving. Keep fighting.', ['Action', 'FPS'], 'Xbox', 'In progress', 9, '2020-03-20', '#b86545', '⟐'],
  ['baldurs-gate-3', 'Baldur’s Gate 3', 'Your story is yours to shape.', ['RPG', 'Strategy'], 'PC', 'Not played', 0, '2023-08-03', '#9373be', '⚔'],
  ['journey', 'Journey', 'Some journeys need no words.', ['Adventure'], 'PlayStation', 'Completed', 4, '2012-03-13', '#c4a17b', '◇'],
];

// All metadata, developers, prices, progress and achievements are fictional demo values.
export const mockGames: Game[] = records.map(([id, title, subtitle, genres, platform, status, playtimeHours, releaseDate, cover, symbol], index) => ({
  id, title, subtitle, genres, platform, status, playtimeHours, releaseDate, cover, symbol, coverUrl: null, rating: null,
  developers: [{ id: `demo-developer-${index + 1}`, foundedYear: null, name: `Demo Studio ${index + 1}`, country: ['Estonia', 'Finland', 'Canada'][index % 3] }],
  fullPrice: [59.99, 14.99, 24.99, 14.99][index % 4],
  lastPlayedDate: playtimeHours ? '2026-09-28' : null,
  achievements: [
    { id: `${id}-achievement-1`, title: 'A new beginning', description: 'Start your first adventure.', unlocked: playtimeHours > 0, unlockedDate: playtimeHours ? '2026-09-01' : null },
    { id: `${id}-achievement-2`, title: 'The long road', description: 'Spend twenty hours exploring.', unlocked: playtimeHours >= 20, unlockedDate: playtimeHours >= 20 ? '2026-09-20' : null },
    { id: `${id}-achievement-3`, title: 'Closing chapter', description: 'Complete the main story.', unlocked: status === 'Completed', unlockedDate: status === 'Completed' ? '2026-09-28' : null },
  ],
}));
