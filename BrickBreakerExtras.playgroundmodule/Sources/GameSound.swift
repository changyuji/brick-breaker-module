//
//  GameSound.swift
//
//  Copyright © 2016-2020 Apple Inc. All rights reserved.
//

import SPCAudio

/// An enumeration of all the different sounds that can be played.
///
/// - localizationKey: GameSound
public enum GameSound: Sound {

    case ballBeepsMono,
    bassBomb,
    blipMono,
    blipMonoMiddle,
    blipMonoRight,
    boing1,
    boing2,
    boing3,
    boop1,
    boop2,
    boop3,
    Bounce1,
    Bounce2,
    Bounce3,
    buttonPress1,
    clang,
    clunk,
    crash,
    defeat1,
    electricBeep1,
    electricBeep2,
    electricBeep3,
    electricBeep4,
    electricBeepFader,
    explosionShort,
    friendlyPassage,
    helicopterWhoosh,
    laser1,
    laser2,
    laser3,
    machineGreeting1,
    machineGreeting2,
    machineGreeting3,
    paddleBassMono,
    pleasantDing1,
    pleasantDing2,
    pleasantDing3,
    pop1,
    pop2,
    powerUp1,
    powerUp2,
    powerUp3,
    powerUp4,
    puzzleJam,
    retroBass,
    retroCollide1,
    retroCollide2,
    retroCollide3,
    retroCollide4,
    retroCollide5,
    retroJump1,
    retroJump2,
    retroPowerUp1,
    retroPowerUp2,
    retroTwang1,
    retroTwang2,
    somethingBad1,
    somethingBad2,
    somethingBad3,
    somethingBad4,
    somethingGood1,
    somethingGood2,
    somethingGood3,
    somethingGood4,
    somethingGood5,
    somethingGood6,
    somethingGood7,
    splat,
    spring1,
    spring2,
    spring3,
    spring4,
    strangeWobble,
    thud,
    tubeHit1,
    tubeHit2,
    tubeHit3,
    victory1,
    victory2,
    victory3,
    victory4,
    warble,
    beam,
    beep,
    blip,
    crystal,
    drop,
    echobird,
    miss,
    pop,
    powerup,
    radiant,
    sonar,
    squeak,
    tick,
    wall,
    warp,
    warpMono,
    zap
}

/// Plays the given sound. Optionally, specify a volume from `0` (silent) to `100` (loudest), with `80` being the default.
///
/// - Parameter sound: The sound to be played.
/// - Parameter volume: The volume at which the sound is to be played (ranging from `0` to `100`).
///
/// - localizationKey: playSound(_:volume:)
public func playSound(_ sound: GameSound, volume: Int = 80) {
    playSound(sound.rawValue, volume: volume)
}

extension Loop {
    /// Creates a Loop with the specified sound and `loopFireHandler`.
    ///
    /// - Parameter sound: The sound played by the Loop.
    /// - Parameter loopFireHandler: The function that gets called each time the loop starts playing the associated sound.
    ///
    /// - localizationKey: Loop(gameSound:loopFireHandler:)
    public convenience init(sound: GameSound, loopFireHandler: (()->Void)? = nil) {
        self.init(sound: sound.rawValue, loopFireHandler: loopFireHandler)
    }
}
