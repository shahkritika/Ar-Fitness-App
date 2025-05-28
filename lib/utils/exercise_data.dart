class ExerciseData {
  static final Map<String, List<Map<String, String>>> exercises = {
    'Strength': [
      {
        'name': 'Squat',
        'video': 'assets/videos/squat.mp4',
        'duration': '30 sec',
        'desc': 'A fundamental lower-body exercise targeting quads, hamstrings, and glutes.',
        'steps': 'Stand with feet shoulder-width apart. Lower your hips as if sitting back into a chair, keeping your chest up. Push through heels to return to standing.'
      },
      {
        'name': 'Pushup',
        'video': 'assets/videos/pushup.mp4',
        'duration': '30 sec',
        'desc': 'A classic upper-body exercise for chest, shoulders, and triceps.',
        'steps': 'Start in a plank position with hands under shoulders. Lower your chest to just above the ground, then push back up to the starting position.'
      },
      {
        'name': 'Deadlift',
        'video': 'assets/videos/Dead_lift.mp4',
        'duration': '30 sec',
        'desc': 'A full-body exercise focusing on the posterior chain.',
        'steps': 'Stand with feet hip-width apart. Hinge at hips, grip the bar, keep back straight, and lift by driving hips forward. Lower with control.'
      },
      {
        'name': 'Bench Press',
        'video': 'assets/videos/benchpress.mp4',
        'duration': '30 sec',
        'desc': 'An upper-body exercise targeting chest, shoulders, and triceps.',
        'steps': 'Lie on a bench, grip barbell slightly wider than shoulder-width. Lower to chest, then press up to full extension.'
      },
      {
        'name': 'Lunge',
        'video': 'assets/videos/lunges.mp4',
        'duration': '30 sec',
        'desc': 'A lower-body exercise improving balance and strength.',
        'steps': 'Step forward with one leg, lowering your hips until both knees are bent at 90 degrees. Push back to start position and switch legs.'
      },
      {
        'name': 'Plank',
        'video': 'assets/videos/plank.mp4',
        'duration': '40 sec',
        'desc': 'A core-strengthening exercise that also engages shoulders and glutes.',
        'steps': 'Lie face down, then prop yourself on forearms and toes, keeping body in a straight line. Hold position without letting hips sag.'
      },
    ],
    'Cardio': [
      {
        'name': 'Jumping Jacks',
        'video': 'assets/videos/jumpingjacks.mp4',
        'duration': '30 sec',
        'desc': 'A full-body cardio exercise to boost heart rate.',
        'steps': 'Stand with feet together, arms at sides. Jump, spreading legs and raising arms overhead, then jump back to start position.'
      },
      {
        'name': 'Mountain Climbers',
        'video': 'assets/videos/mountain.mp4',
        'duration': '30 sec',
        'desc': 'A dynamic cardio move that also strengthens the core.',
        'steps': 'Start in a plank position. Drive one knee toward chest, then quickly switch legs, mimicking a running motion.'
      },
      {
        'name': 'Running in Place',
        'video': 'assets/videos/running.mp4',
        'duration': '30 sec',
        'desc': 'A simple cardio exercise to elevate heart rate.',
        'steps': 'Stand with feet hip-width apart. Jog in place, lifting knees high and pumping arms.'
      },
      {
        'name': 'High Knees',
        'video': 'assets/videos/highknees.mp4',
        'duration': '30 sec',
        'desc': 'A high-intensity cardio exercise targeting core and legs.',
        'steps': 'Run in place, lifting knees to hip level with each step, pumping arms for momentum.'
      },
    ],
  };

  static String getArType(String exerciseName, String workoutType) {
    final formattedName = exerciseName.toLowerCase().replaceAll(' ', '_');
    const arSupportedExercises = [
      'squat',
      'pushup',
      'deadlift',
      'bench_press',
      'lunge',
      'plank',
      'jumping_jacks',
      'mountain_climbers',
      'running_in_place',
      'high_knees',
    ];
    return arSupportedExercises.contains(formattedName) ? 'AR' : 'Standard';
  }

  static String getNormalizedWorkoutType(String exerciseName) {
    return exerciseName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w_]'), '');
  }
}