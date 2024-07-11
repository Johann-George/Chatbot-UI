import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:personal_trainer_app/message_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
/// The state class for HomeScreen, responsible for maintaining state
/// and building the UI for the chat application.
class _HomeScreenState extends State<HomeScreen> {
  // The generative model instance.
  late final GenerativeModel _model;
  // The chat session instance.
  late final ChatSession _chatSession;
  // Focus node for the text field.
  final FocusNode _textFieldFocus=FocusNode();
  // Text editing controller for the text field.
  final TextEditingController _textController=TextEditingController();
  // Scroll controller for the list view.
  final ScrollController _scrollController=ScrollController();
  // Loading state indicator.
  bool _loading=false;

  /// Initializes the state and sets up the generative model and chat session.
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _model= GenerativeModel(
        model: 'gemini-pro',
        apiKey: const String.fromEnvironment('api_key'),
    );
    _chatSession=_model.startChat();
  }

  /// Builds the widget tree for the home screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build with Gemini'),
      ),
      body:Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _chatSession.history.length,
                itemBuilder: (column,index){
                  final Content content=_chatSession.history.toList()[index];
                  final text=content.parts.whereType<TextPart>().map<String>((e)=> e.text).join('');
                  return MessageWidget(
                      text: text,
                      isFromUser: content.role=='user',
                  );
                },
              ),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 25,
                  horizontal: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: TextField(
                          autofocus: true,
                          focusNode: _textFieldFocus,
                          decoration: textFieldDecoration(),
                          controller: _textController,
                          onSubmitted: _sendChatMessage,
                        ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_textController.text.isNotEmpty) {
                          _sendChatMessage(_textController.text);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the decoration for the text field.
  InputDecoration textFieldDecoration(){
    return InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt:',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary
        ),
      ),
    );
  }

  /// Sends a chat message to the generative model and handles the response.
  Future<void> _sendChatMessage(String message) async{
    setState(() {
      _loading=true;
    });

    try{
      final response=await _chatSession.sendMessage(
        Content.text(message),
      );
      final text=response.text;
      if(text==null){
        _showError('No response from API');
        return;
      }
      else{
        setState(() {
          _loading=false;
          _scrollDown();
        });
      }
    }
    catch(e){
      _showError(e.toString());
      setState(() {
        _loading=false;
      });
    }
    finally{
      _textController.clear();
      setState(() {
        _loading=false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  /// Scrolls down the list view to show the latest message.
  void _scrollDown(){
    WidgetsBinding.instance.addPostFrameCallback(
        (_)=>_scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:const Duration(
            milliseconds: 750,
          ),
          curve: Curves.easeOutCirc,
        ),
    );
  }

  /// Shows an error dialog with the provided message.
  void _showError(String message){
    showDialog<void>(
      context: context,
      builder: (context){
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
                onPressed: (){
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}
