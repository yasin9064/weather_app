import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyLarge: const TextStyle(color: Colors.white),
          bodyMedium: const TextStyle(color: Colors.white),
          displayLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displayMedium: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displaySmall: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineSmall: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      home: const WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final String _apiKey = '76a9785a425b05f5db0f084a7e432c5e';
  String _cityName = '';
  String _temperature = '';
  String _weatherDescription = '';
  String _humidity = '';
  String _windSpeed = '';
  String _feelsLike = '';
  String _sunrise = '';
  String _sunset = '';
  String _pressure = '';
  List<dynamic> _forecast = [];
  bool _isLoading = false;

  final TextEditingController _cityController = TextEditingController();

  Future<void> _getWeather(String city) async {
    if (city.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final weatherResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$_apiKey&units=metric'));

      if (weatherResponse.statusCode == 200) {
        final weatherData = jsonDecode(weatherResponse.body);
        final forecastResponse = await http.get(Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$_apiKey&units=metric'));

        if (forecastResponse.statusCode == 200) {
          final forecastData = jsonDecode(forecastResponse.body);
          setState(() {
            _cityName = weatherData['name'];
            _temperature = weatherData['main']['temp'].toStringAsFixed(1);
            _weatherDescription = weatherData['weather'][0]['description'];
            _humidity = weatherData['main']['humidity'].toString();
            _windSpeed = weatherData['wind']['speed'].toString();
            _feelsLike = weatherData['main']['feels_like'].toStringAsFixed(1);
            _pressure = weatherData['main']['pressure'].toString();
            _sunrise = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(weatherData['sys']['sunrise'] * 1000));
            _sunset = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(weatherData['sys']['sunset'] * 1000));
            _forecast = forecastData['list'];
            _isLoading = false;
          });
        } else {
          _showError('Failed to load forecast data.');
        }
      } else {
        _showError('Failed to load weather data.');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final city = placemarks[0].locality;
        if (city != null) {
          _getWeather(city);
        } else {
          _showError('Could not determine city from location.');
        }
      }
    } catch (e) {
      _showError('Failed to get current location: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocationWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.blue.shade900],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSearchbar(),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _buildWeatherContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cityController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Enter City',
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => _getWeather(_cityController.text),
        ),
        IconButton(
          icon: const Icon(Icons.location_on, color: Colors.white),
          onPressed: _getCurrentLocationWeather,
        ),
      ],
    );
  }

  Widget _buildWeatherContent() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _cityName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '$_temperature°C',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 10),
            Text(
              _weatherDescription,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherInfo('Humidity', '$_humidity%'),
                _buildWeatherInfo('Wind Speed', '$_windSpeed m/s'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherInfo('Feels Like', '$_feelsLike°C'),
                _buildWeatherInfo('Pressure', '$_pressure hPa'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherInfo('Sunrise', _sunrise),
                _buildWeatherInfo('Sunset', _sunset),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              '5-Day Forecast',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            _buildForecastList(),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastList() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _forecast.length,
        itemBuilder: (context, index) {
          final item = _forecast[index];
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          return Card(
            color: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    DateFormat('E, ha').format(date),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Image.network(
                      'https://openweathermap.org/img/w/${item['weather'][0]['icon']}.png'),
                  Text(
                    '${item['main']['temp'].toStringAsFixed(1)}°C',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherInfo(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}