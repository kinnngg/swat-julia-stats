# -*- coding: utf-8 -*-
import os

from unipath import Path
from fabric.api import *


env.kits = {
    'swat4': {
        'mod': 'Mod',
        'content': 'Content',
        'server': 'Swat4DedicatedServer.exe',
        'ini': 'Swat4DedicatedServer.ini',
    },
    'swat4exp': {
        'mod': 'ModX',
        'content': 'ContentExpansion',
        'server': 'Swat4XDedicatedServer.exe',
        'ini': 'Swat4XDedicatedServer.ini',
    },
}

env.roledefs = {
    'ucc': ['vm-ubuntu-swat'],
    'server': ['vm-ubuntu-swat'],
}

env.paths = {
    'here': Path(os.path.dirname(__file__)).parent,
}

env.paths.update({
    'dist': env.paths['here'].child('dist'),
    'compiled': env.paths['here'].child('compiled'),
})

env.ucc = {
    'path': Path('/home/sergei/swat4ucc/'),
    'git': 'git@home:public/swat4#origin/ucc',
    'packages': (
        ('Utils', 'git@home:swat/swat-utils'),
        ('Julia', 'git@home:swat/swat-julia'),
        ('JuliaStats', 'git@home:swat/swat-julia-stats'),
    ),
}

env.server = {
    'path': Path('/home/sergei/swat4server/'),
    'git': 'git@home:public/swat4#origin/server-bs',
    'settings': {

        '+[Engine.GameEngine]': (
            'ServerActors=Utils.Package',
            'ServerActors=Julia.Core',
            'ServerActors=JuliaStats.Extension',
        ),
        '[Julia.Core]': (
            'Enabled=True',
        ),
        '[JuliaStats.Locale]': (
            ';MessageColor=FF00FF',
        ),
        '[JuliaStats.Extension]': (
            'Enabled=True',

            'VariableStats=HIGHEST_HITS',
            'VariableStats=LOWEST_HITS',
            'VariableStats=HIGHEST_TEAM_HITS',
            'VariableStats=LOWEST_TEAM_HITS',
            'VariableStats=HIGHEST_AMMO_FIRED',
            'VariableStats=LOWEST_AMMO_FIRED',
            'VariableStats=HIGHEST_ACCURACY',
            'VariableStats=LOWEST_ACCURACY',
            'VariableStats=HIGHEST_NADE_HITS',
            'VariableStats=LOWEST_NADE_HITS',
            'VariableStats=HIGHEST_NADE_TEAM_HITS',
            'VariableStats=LOWEST_NADE_TEAM_HITS',
            'VariableStats=HIGHEST_NADE_THROWN',
            'VariableStats=LOWEST_NADE_THROWN',
            'VariableStats=HIGHEST_NADE_ACCURACY',
            'VariableStats=LOWEST_NADE_ACCURACY',
            'VariableStats=HIGHEST_KILL_DISTANCE',
            'VariableStats=LOWEST_KILL_DISTANCE',
            'VariableStats=HIGHEST_SCORE',
            'VariableStats=LOWEST_SCORE',
            'VariableStats=HIGHEST_KILLS',
            'VariableStats=LOWEST_KILLS',
            'VariableStats=HIGHEST_ARRESTS',
            'VariableStats=LOWEST_ARRESTS',
            'VariableStats=HIGHEST_ARRESTED',
            'VariableStats=LOWEST_ARRESTED',
            'VariableStats=HIGHEST_TEAM_KILLS',
            'VariableStats=LOWEST_TEAM_KILLS',
            'VariableStats=HIGHEST_SUICIDES',
            'VariableStats=LOWEST_SUICIDES',
            'VariableStats=HIGHEST_DEATHS',
            'VariableStats=LOWEST_DEATHS',
            'VariableStats=HIGHEST_KILL_STREAK',
            'VariableStats=LOWEST_KILL_STREAK',
            'VariableStats=HIGHEST_ARREST_STREAK',
            'VariableStats=LOWEST_ARREST_STREAK',
            'VariableStats=HIGHEST_DEATH_STREAK',
            'VariableStats=LOWEST_DEATH_STREAK',
            'VariableStats=HIGHEST_VIP_CAPTURES',
            'VariableStats=LOWEST_VIP_CAPTURES',
            'VariableStats=HIGHEST_VIP_RESCUES',
            'VariableStats=LOWEST_VIP_RESCUES',
            'VariableStats=HIGHEST_BOMBS_DEFUSED',
            'VariableStats=LOWEST_BOMBS_DEFUSED',
            'VariableStats=HIGHEST_CASE_KILLS',
            'VariableStats=LOWEST_CASE_KILLS',
            'VariableStats=HIGHEST_REPORTS',
            'VariableStats=LOWEST_REPORTS',
            'VariableStats=HIGHEST_HOSTAGE_ARRESTS',
            'VariableStats=LOWEST_HOSTAGE_ARRESTS',
            'VariableStats=HIGHEST_HOSTAGE_HITS',
            'VariableStats=LOWEST_HOSTAGE_HITS',
            'VariableStats=HIGHEST_HOSTAGE_INCAPS',
            'VariableStats=LOWEST_HOSTAGE_INCAPS',
            'VariableStats=HIGHEST_HOSTAGE_KILLS',
            'VariableStats=LOWEST_HOSTAGE_KILLS',
            'VariableStats=HIGHEST_ENEMY_ARRESTS',
            'VariableStats=LOWEST_ENEMY_ARRESTS',
            'VariableStats=HIGHEST_ENEMY_INCAPS',
            'VariableStats=LOWEST_ENEMY_INCAPS',
            'VariableStats=HIGHEST_ENEMY_KILLS',
            'VariableStats=LOWEST_ENEMY_KILLS',
            'VariableStats=HIGHEST_ENEMY_INCAPS_INVALID',
            'VariableStats=LOWEST_ENEMY_INCAPS_INVALID',
            'VariableStats=HIGHEST_ENEMY_KILLS_INVALID',
            'VariableStats=LOWEST_ENEMY_KILLS_INVALID',

            'VariableStatsLimit=5',

            'FixedStats=HIGHEST_HITS',
            'FixedStats=LOWEST_HITS',

            'PlayerStats=ACCURACY',
            'PlayerStats=HITS',
            'PlayerStats=AMMO_FIRED',
            'PlayerStats=NADE_ACCURACY',
            'PlayerStats=NADE_HITS',
            'PlayerStats=NADE_THROWN',
            'PlayerStats=TEAM_HITS',
            'PlayerStats=NADE_TEAM_HITS',

            'MinTimeRatio=0',
        ),
    }
}

env.dist = {
    'version': '1.0.0',
    'extra': (
        env.paths['here'].child('LICENSE'),
        env.paths['here'].child('README.html'),
        env.paths['here'].child('CHANGES.html'),
    )
}