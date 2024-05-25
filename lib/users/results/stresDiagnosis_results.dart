import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mentalsehat/users/Meditation/stresTrackList.dart';
import 'package:mentalsehat/users/answer/user_answer.dart';
import 'package:mentalsehat/users/solution/stres_solution.dart';

class StressDiagnosisResults extends StatefulWidget {
  final int totalScore;
  final List<UserAnswer> userAnswers;

  StressDiagnosisResults({
    required this.totalScore,
    required this.userAnswers,
  });

  @override
  _StressDiagnosisResultsState createState() => _StressDiagnosisResultsState();
}

class _StressDiagnosisResultsState extends State<StressDiagnosisResults> {
   bool _isDataSaved = false;
   final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        // Handle connectivity changes here if needed
        setState(() {}); // Trigger rebuild when connectivity changes
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
  
  String _getResultCategory() {
    int totalScore = widget.totalScore;

    if (totalScore >= 0 && totalScore <= 14) {
      return "Normal";
    } else if (totalScore >= 15 && totalScore <= 18) {
      return "Stres Ringan";
    } else if (totalScore >= 19 && totalScore <= 25) {
      return "Stres Sedang";
    } else if (totalScore >= 26 && totalScore <= 33) {
      return "Stres Parah";
    } else {
      return "Stres Sangat Parah";
    }
  }
  
  

  String _getSolution() {
    String resultCategory = _getResultCategory();
    String solution = '';

    switch (resultCategory) {
      case "Normal":
        solution = StressSolutionData.solutions
            .firstWhere((s) => s.kode == "SS01")
            .value;
        break;
      case "Stres Ringan":
        solution = StressSolutionData.solutions
            .firstWhere((s) => s.kode == "SS02")
            .value;
        break;
      case "Stres Sedang":
        solution = StressSolutionData.solutions
            .firstWhere((s) => s.kode == "SS03")
            .value;
        break;
      case "Stres Parah":
        solution = StressSolutionData.solutions
            .firstWhere((s) => s.kode == "SS04")
            .value;
        break;
      case "Stres Sangat Parah":
        solution = StressSolutionData.solutions
            .firstWhere((s) => s.kode == "SS05")
            .value;
        break;
      default:
        break;
    }

    return solution;
  }

  bool _showDetails = false;

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'February';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return '';
    }
  }

  String _getDayName(int day) {
    switch (day) {
      case DateTime.sunday:
        return 'Minggu';
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      default:
        return '';
    }
  }

  void _saveDiagnosis(String selectedCategory) async {
    try {
      // Mendapatkan waktu saat ini
      DateTime now = DateTime.now();
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      String formattedDate = "${_getDayName(now.weekday)}, ${now.day} ${_getMonthName(now.month)} ${now.year}";
      String formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      // Mengambil ID user yang sedang login
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;
        Map<String, dynamic> diagnosisData = {
          'category': selectedCategory,
          'timestamp': timestamp,
          'date': formattedDate,
          'time': formattedTime,
          'score': widget.totalScore,
          'result_category': _getResultCategory(),
          'solution': _getSolution(),
          'detail': widget.userAnswers
              .asMap()
              .map((key, value) => MapEntry(
                    key.toString(),
                    {
                      'question': value.question,
                      'answer': value.answer,
                    },
                  ))
              .values
              .toList(),
        };

        // Menyimpan data ke Firestore
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('HistoryDiagnosis')
            .add(diagnosisData);

        // Tampilkan snackbar pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Diagnosis berhasil disimpan',
              style: TextStyle(
                fontFamily:'Poppins', 
                color: Colors.white
              ),
            ),
            duration: Duration(seconds: 2),
            backgroundColor:Colors.green, 
          ),
        );
        setState(() {
          _isDataSaved = true;
        });
      }
    } catch (e) {
      print('Error saving diagnosis: $e');
      // Tangkap dan tangani kesalahan di sini
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: _connectivity.onConnectivityChanged,
      initialData: ConnectivityResult.mobile,
      builder: (context, snapshot) {
        if (snapshot.data == ConnectivityResult.none) {
          // Tidak ada koneksi internet
          return _buildNoInternet();
        } else {
          // Terdapat koneksi internet
          return _buildStresDiagnosisResult();
        }
      },
    );
  }

  Widget _buildNoInternet() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
              size: 60,
            ),
            SizedBox(height: 8),
            Image.asset(
              'images/noInternet.png',
              width: 200,
              height: 200,
            ),
            Text(
              "Oops!",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Sepertinya sambungan anda telah terputus",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Silahkan cek kembali koneksi internet anda",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStresDiagnosisResult() {
    String resultCategory = _getResultCategory();
    String imagePath = '';

    switch (resultCategory) {
      case "Normal":
        imagePath = 'images/stres_normal.png';
        break;
      case "Stres Ringan":
        imagePath = 'images/stres_ringan.png';
        break;
      case "Stres Sedang":
        imagePath = 'images/stres_sedang.png';
        break;
      case "Stres Parah":
        imagePath = 'images/stres_parah.png';
        break;
      case "Stres Sangat Parah":
        imagePath = 'images/stres_sangatparah.png';
        break;
      default:
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hasil Diagnosa',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Nilai kamu',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '${widget.totalScore}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Image.asset(
                imagePath,
                width: 150,
                height: 150,
              ),
              SizedBox(height: 16),
              Text(
                'Kategori: ${_getResultCategory()}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    'Solusi:',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                _getSolution(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
               SizedBox(height: 12),
             RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black, // Set the text color
                ),
                children: [
                  TextSpan(
                    text: "Cobalah melakukan meditasi mindfulness 'Mengurangi Stres' ",
                  ),
                  TextSpan(
                    text: 'Disini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StresTrackList(),
                          ),
                        );
                      },
                  ),
                ],
              ),
            ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detail Diagnosa:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showDetails
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                        ),
                        onPressed: () {
                          setState(() {
                            _showDetails = !_showDetails;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_showDetails)
                    ...widget.userAnswers.asMap().entries.map((entry) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Color(0xFF91D0EB),
                              ),
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.key + 1}. ${entry.value.question}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Jawaban: ${entry.value.answer}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )),
                  SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: double
                          .infinity, // Lebarkan tombol ke seluruh lebar layar
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                          onPressed: _isDataSaved
                            ? null // Nonaktifkan tombol jika data sudah disimpan
                            : () {
                                _saveDiagnosis('Diagnosa Stres');
                              },
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFF04558F),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16), // Atur padding vertikal
                          child: Text(
                            'Simpan',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
