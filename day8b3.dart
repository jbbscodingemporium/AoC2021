import 'dart:io';
import 'dart:math';

var segments = ["ABCEFG",   //0
                "CF",       //1
                "ACDEG",    //2
                "ACDFG",    //3
                "BCDF",     //4
                "ABDFG",    //5
                "ABDEFG",   //6
                "ACF",      //7
                "ABCDEFG",  //8
                "ABCDFG"    //9
                ];

List<int> getPossibleNumerals(String seq, Map<String, String> solset) {
  var evalNumerals = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].where((v) => segments[v].length == seq.length).toList();
  var possibleSegmentUnion = [for (var s in seq.split('')) solset[s]!].fold("", (String previousValue, element) => previousValue + element);
  List<int> possibleNumerals = [];
  for (var numeral in evalNumerals) {
    var possible = [for (var segment in segments[numeral].split('')) possibleSegmentUnion.contains(segment) ].fold(true, (bool a,b) => a && b);
    if (possible) { possibleNumerals.add(numeral); }
  }
  return possibleNumerals;
}

//Returns true if possibly a solution and false if not a solution.
bool propagateSolutionSet(List<String> sequences, Map<String, String> solset) {
  int newSolutionSize = [for (var possibilities in solset.values) possibilities.length ].fold(0, (a,b) => a+b);
  int oldSolutionSize = newSolutionSize;
  do {
    oldSolutionSize = newSolutionSize;

    //Propagate given the solution set.
    for (var seq in sequences) {
      var possibleNumerals = getPossibleNumerals(seq, solset);
      //Given the above numerals are the only ones possible, the possibleSegments are the only segments that are possible.
      var possibleSegments = [for (var v in possibleNumerals) segments[v]].fold("", (String a,b) => a + b);
      //Remove the segments that can't be part of this sequence - only segments belonging to numbers that this seq could represent.
      for (var trace in seq.split("")) {
        var newSet = solset[trace]!.split("").where((a) => possibleSegments.contains(a)).toList();
        solset[trace] = newSet.fold("",(String a, b) => a + b);
      }
    }

    //If a trace is known to match a segment, remove that segment from all other traces.
    var uniqueTraces = solset.keys.where((a) => solset[a]!.length == 1).toList();
    for (var uTrace in uniqueTraces) {
      var uniqueSegment = solset[uTrace]!;
      for (var trace in solset.keys) {
        if (trace == uTrace) { continue; }
        solset[trace] = solset[trace]!.replaceAll(uniqueSegment,"");
      }
    }

    var tracesWithNoSolution = [for (var k in solset.keys) if (solset[k]!.isEmpty) k];
    if (tracesWithNoSolution.isNotEmpty) { return false; }

    newSolutionSize = [for (var possibilities in solset.values) possibilities.length ].fold(0, (a,b) => a+b);
  } while (oldSolutionSize != newSolutionSize);

  return true;
}

Map<String,String>? solveRecursively(List<String> sequences, Map<String,String> solset) {
  //Propagate the solution using whatever's already been determined.
  bool potentiallySolvable = propagateSolutionSet(sequences, solset);
  if (!potentiallySolvable) { return null; }

  //Check to see if we have a solution.
  var solutionLengths = solset.values.map((e) => e.length).toList();
  bool solutionFound = solutionLengths.fold(true, (bool a, int b) => a && b == 1);
  if (solutionFound) { return solset; }

  //Isolate a single variable and go recursive.
  var unsolvedTrace = solset.keys.where((a) => solset[a]!.length > 1).toList()[0];
  var candidates = solset[unsolvedTrace]!.split("");
  for (var candidate in candidates) {
    var newSolset = Map<String,String>.from(solset);
    newSolset[unsolvedTrace] = candidate;
    var result = solveRecursively(sequences, newSolset);
    if (result != null) { return result; }
  }

  return null;
}

int getResult(List<String> sequences, List<String> outputs) {
  String allTraces = "abcdefg";
  String allSegments = "ABCDEFG";

  Map<String,String> newSolset = { for (var trace in allTraces.split('')) trace : allSegments };

  var answer = solveRecursively(sequences, newSolset);
  if (answer == null) throw ("Could not find an answer!");

  var result = 0;
  for (var o in outputs) {
    for (var trace in answer.keys) {
      o = o.replaceAll(trace, answer[trace]!);
    }
    var sorted = o.split("")..sort();
    var sortedString = sorted.fold("",(String a, b) => a + b);
    int numeral = segments.indexOf(sortedString);
    result = result * 10 + numeral;
  }

  return result;
}

void main(List<String> arguments) {  
  var stopwatch = Stopwatch()..start();  

  var inputs = File("day8.txt").readAsLinesSync();
  List<List<String>> outputs = [for (var inp in inputs) inp.split('|')[1].trim().split(' ') ];
  List<List<String>> sequences = [for (var inp in inputs) inp.replaceAll('| ', '').split(' ') ];

  int totalScore = 0;
  for (int i = 0; i < sequences.length; ++i) {
    totalScore += getResult(sequences[i], outputs[i]);
  }
  print("TOTAL SCORE: $totalScore");

  print("Stopwatch: ${stopwatch.elapsed}");
}