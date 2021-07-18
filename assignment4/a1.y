%union {
    struct node* snod;
}

%token ID INTCONST FLOATCONST 
%token PRINTF FRMT_SPEC SCANF
%token OROP ANDOP EQOP NEQOP GEQOP COMOP LEQOP POIOP DECOP INCOP SIZEOF 
%token BREAK CASE CONTINUE DEFAULT DO ELSE EXTERN FLOAT IF INT RETURN STRUCT SWITCH VOID WHILE
%token LBRACKET RBRACKET LBRACES RBRACES LCURLY RCURLY DOT AND STAR ADD SUB NOT DIV MOD LESSER GREATER SEMICOLON EQUAL COMMA COLON

%type <snod> program decl_list decl struct_decl var_decl type_spec extern_spec func_decl params param_list param stmt_list stmt while_stmt dowhile_stmt print_stmt scan_stmt format_specifier compound_stmt local_decls local_decl if_stmt return_stmt break_stmt continue_stmt switch_stmt compound_case single_case default_case assign_stmt incr_stmt decr_stmt expr Pexpr arg_list args integerLit floatLit identifier

%{
    #include <bits/stdc++.h>
    using namespace std;
    #define TEXT(a) #a
    #define NTYPES 100
    #define TS(i, j, k) (to_string(i)+","+to_string(j)+","+to_string(k))
    typedef long long int ll;

    ofstream mfile;

	void yyerror(char *);
	int yylex(void);
	char mytext[100];
    int syntax = 0;
    extern char *yytext;
    extern long long int lineno;
    long long int astlp = 0;
    long long int iflp = 0;
    long long int whilelp = 0;
    long long int switchlp = 0;
    long long int mainlp = 0;
    long long int offs = 0;
    long long int soffs = 0;
    long long int npara = 0;
    long long int narg = 0;
    int retu = 1;
    unordered_map < string, long long int > symtab;
    unordered_map < string, long long int > funtab;
    unordered_map < string, long long int > paramtab;
    unordered_map < string, long long int > arraysize;
    unordered_map < string, long long int > csub;
    unordered_set < string > used;
    long long int vncount = 0;
    int insideif = 0;
    vector <struct node*> cseif;
    unordered_set < long long int > common;
    unordered_map < string, struct node* > ssa;

    bool cmpBy(pair <string, long long int> a, pair <string, long long int> b){
        return symtab[a.first] < symtab[b.first];
    }

    vector <string> unused;
    int ifflag = 1;
    int isif = 0;
    map < long long int, long long int > sred;
    map < long long int, long long int > sred2;
    map < long long int, long long int > cfold;
    map < long long int, long long int > cfold2;
    map <long long int,  vector <pair <string, long long int > > >cprop;
    map < long long int, set <long long int> > pcse;
    
    enum ntype{
        program,
        decl_list,
        decl,
        struct_decl,
        var_decl,
        type_spec,
        extern_spec,
        func_decl,
        params,
        param_list,
        param,
        stmt_list,
        stmt,
        expr_stmt,
        while_stmt,
        dowhile_stmt,
        print_stmt,
        scan_stmt,
        format_specifier,
        compound_stmt,
        local_decls,
        local_decl,
        if_stmt,
        return_stmt,
        break_stmt,
        continue_stmt,
        switch_stmt,
        compound_case,
        single_case,
        default_case,
        assign_stmt,
        incr_stmt,
        decr_stmt,
        expr,
        Pexpr,
        arg_list,
        args,
        integerLit,
        floatLit,
        identifier,
        lcurly,
        rcurly,
        semicolon,
        comma,
        lbracket,
        rbracket,
        dot,
        lbraces,
        rbraces,
        star,
        Equal,
        colon,
        Greater,
        lesser,
        add,
        sub,
        Div,
        mod,
        Not,
        And,
        id,
        intconst,
        floatconst, 
        Printf, 
        Scanf,
        frmt_spec,
        orop, 
        andop, 
        eqop, 
        neqop, 
        geqop, 
        comop, 
        leqop, 
        poiop, 
        decop, 
        incop, 
        Sizeof, 
        Break, 
        Case, 
        Continue, 
        Default, 
        Do, 
        Else, 
        Extern, 
        Float, 
        If, 
        Int, 
        Return, 
        Struct, 
        Switch, 
        Void, 
        While,
        epsilon
    };
    #define ArithB (node->nt == add || node->nt == sub || node->nt == star || node->nt == Div || node->nt == mod)
    #define Bin (node->nt == orop || node->nt == andop)
    #define RelB (node->nt == lesser || node->nt == Greater || node->nt == leqop || node->nt == geqop || node->nt == eqop || node->nt == neqop)

    string typenam[] = {"program", "decl_list", "decl", "struct_decl", "var_decl", "type_spec", "extern_spec", "func_decl", "params", "param_list", "param", "stmt_list", "stmt", "expr_stmt", "while_stmt", "dowhile_stmt", "print_stmt", "scan_stmt", "format_specifier", "compound_stmt", "local_decls", "local_decl", "if_stmt", "return_stmt", "break_stmt", "continue_stmt", "switch_stmt", "compound_case", "single_case", "default_case", "assign_stmt", "incr_stmt", "decr_stmt", "expr", "Pexpr", "arg_list", "args", "integerLit", "floatLit", "identifier", "lcurly", "rcurly", "semicolon", "comma", "lbracket", "rbracket", "dot", "lbraces", "rbraces", "imull", "Equal", "colon", "setg", "setl", "addl", "subl", "idivl", "idivl", "Not", "And", "id", "intconst", "floatconst", "Printf", "Scanf", "frmt_spec", "addl", "imull", "sete", "setne", "setge", "comop", "setle", "poiop", "decop", "incop", "Sizeof", "Break", "Case", "Continue", "Default", "Do", "Else", "Extern", "Float", "If", "Int", "Return", "Struct", "Switch", "Void", "While", "epsilon"};

    struct node{
        enum ntype nt;
        struct node* children[9];
        int nchild;
        int constant;
        string str;
        long long int offset;
        long long int value;
        long long int vn;
        long long int line;
        int consflag;
        /*long long int height;
        long long int lp;*/
    };

    void nodecopy(struct node* node1, struct node* node2){
        node1->nt = node2->nt;
        for(int i=0;i<9;i++){
            node1->children[i] = node2->children[i];
        }
        node1->nchild = node2->nchild;
        node1->constant = node2->constant;
        if(node2->str != "")
            node1->str = node2->str;
        node1-> offset = node2-> offset;
        node1-> value = node2-> value;
        node1-> vn = node2-> vn;
        node1->line = node2->line;
        node1->consflag = node2->consflag;
    }

    struct node* phi(struct node* node1, struct node* node2){
        if(node1->vn == node2->vn){
            return node2;
        }
        struct node* node = (struct node*) malloc(sizeof(struct node));
        node->nt = id;
        node->str = node1->str;
        node->constant = 0;
        node->value = 0;
        if(node1->constant && node2->constant)  
            if(node1->value == node2->value){
                node->constant = 1;
                node->value = node1->value;
            }
        node->nchild = 0;
        node->consflag = 0;
        node->vn = ++vncount;
        for(int i=0; i<9;i++){
            node->children[i] = NULL;
        }
        return node;
    }

    long long int max(long long int num1, long long int num2){
        return (num1 > num2 ) ? num1 : num2;
    }

    struct node* cons_lexstr(enum ntype a, string sr){
        //printf("malloc1\n");
        struct node* newnode = (struct node*) malloc(sizeof(struct node));
        newnode->nt = a;
        newnode->constant = 0;
        if(a==intconst){
            newnode->constant = 1;
            newnode->value = stoi(sr);
            //mfile<<newnode->value<<endl;
        }
        newnode->nchild = 0;
        for(int i=0; i<9;i++){
            newnode->children[i] = NULL;
        }
        //newnode->str = "init";
        newnode->str = sr;
        newnode->line = lineno;
        newnode->consflag = 0;
        return newnode;
    }

    struct node* cons_lex(enum ntype a){
        //printf("malloc2\n");
        struct node* newnode = (struct node*) malloc(sizeof(struct node));
        newnode->nt = a;
        newnode->nchild = 0;
        newnode->constant = 0;
        for(int i=0; i<9;i++){
            newnode->children[i] = NULL;
        }
        newnode->line = lineno;
        newnode->consflag = 0;
        return newnode;
    }

    struct node* cons_rep(enum ntype typ, int c, struct node* nodarr[]){
        //printf("malloc3\n");
        //mfile<<typenam[typ]<<" "<<lineno<<endl;
        struct node* nod = (struct node*) malloc(sizeof(struct node));
        nod->nt = typ;
        nod->nchild = c;
        nod->constant = 0;
        //printf("malloc4\n");
        for(int i=0; i<c; i++){
            nod->children[i] = nodarr[i];
        }
        /*long long int maxlp = 0;
        long long int maxh = 0;
        long long int smaxh = 0;
        for(int i=0; i<c; i++){
            maxlp = max(maxlp, nodarr[i]->lp);
            if((nodarr[i]->height)>maxh){
                smaxh = maxh;
                maxh = (nodarr[i]->height);
            }
            else{
                if((nodarr[i]->height)>smaxh){
                    smaxh = (nodarr[i]->height);
                }
            }
        }
        nod->height = maxh + 1;
        nod->lp = max(maxlp, maxh+smaxh+1);
        //printf("%s, %lld\n", typename[typ], nod->height);
        if(typ==program){
            astlp = nod->lp;
        }
        if(typ==if_stmt){
            iflp = max(iflp, nod->lp);
        }
        if(typ==while_stmt){
            whilelp = max(whilelp, nod->lp);
        }
        if(typ==switch_stmt){
            switchlp = max(switchlp, nod->lp);
        }
        if(typ==func_decl && (nodarr[1]->children[0]->str == "main")){
            mainlp = max(mainlp, nod->lp);
        }*/
        nod->line = lineno;
        nod->consflag = 0;
        return nod;
    }

    struct node* cons_int(long long int a, long long int line){
        struct node* newnode = (struct node*) malloc(sizeof(struct node));
        newnode->nt = Pexpr;
        newnode->nchild = 1;
        newnode->constant = 1;
        newnode->value = a;
        newnode->children[0] = cons_rep(integerLit, 1, new struct node*[1] {cons_lexstr(intconst, to_string(a))});
        newnode->line = line;
        newnode->consflag = 1;
        newnode->children[0]->consflag = 1;
        newnode->children[0]->children[0]->consflag = 1;
        newnode->children[0]->line = line;
        newnode->children[0]->children[0]->line = line;
        return newnode;
    }

    void genconst(string s){
        mfile<<"movl $"<<s<<", %eax"<<endl;
    }

    void push(string s){
        mfile<<"pushq %"<<s<<endl;
    }

    void pop(string s){
        mfile<<"popq %"<<s<<endl;
    }

    void pushl(string s){
        mfile<<"subq $4, %rsp"<<endl;
        mfile<<"movl "<<s<<", (%rsp)"<<endl;
    }

    void popl(string s){
        mfile<<"movl (%rsp), "<<s<<endl;
        mfile<<"addq $4, %rsp"<<endl;
    }

    long long int coun = 0;
    string uniqlabel(string s){
        s = s + to_string(coun);
        coun++;
        return s;
    }

    string getpara(long long int i){
        if(i==0){
            return "%edi";
        }
        else if(i==1){
            return "%esi";
        }
        else if(i==2){
            return "%edx";
        }
        else if(i==3){
            return "%ecx";
        }
        else if(i==4){
            return "%r8d";
        }
        else if(i==5){
            return "%r9d";
        }
        else {
            return "-" + to_string((i-3)*4) + "(%rbp)";
        }
    }

    void genlabel(string s){
        mfile<<s<<":"<<endl;
    } 

    void gotol(string s){
        mfile<<"jmp "<<s<<endl;
    }

    void enter(){
        mfile<<"endbr64"<<endl;
        push("rbp");
        mfile<<"movq %rsp, %rbp"<<endl;
        for(auto i : common){
            soffs += 4;
            mfile<<"subq $4, %rsp"<<endl;
            mfile<<"movl $0, (%rsp)"<<endl;
        }
    }

    void srinsert(long long int line, long long int constant){
        if(sred.count(line)){
            if(constant > sred[line]){
                sred[line] = constant;
            }
        }
        else{
            sred[line] = constant;
        }
    }

    void srinsert2(long long int line, long long int constant){
        if(sred2.count(line)){
            if(constant > sred2[line]){
                sred2[line] = constant;
            }
        }
        else{
            sred2[line] = constant;
        }
    }

    void cfinsert(long long int line, long long int constant){
        if(cfold.count(line)){
            if(constant > cfold[line]){
                cfold[line] = constant;
            }
        }
        else{
            cfold[line] = constant;
        }
    }

    void cfinsert2(long long int line, long long int constant){
        if(cfold2.count(line)){
            if(constant > cfold2[line]){
                cfold2[line] = constant;
            }
        }
        else{
            cfold2[line] = constant;
        }
    }

    void cpinsert(long long int line, string constant, long long int value){
        if(cprop.count(line)){
            cprop[line].push_back(make_pair(constant, value));
        }
        else{
            vector < pair <string, long long int> > temp;
            temp.push_back(make_pair(constant, value));
            cprop[line] = temp;
        }
    }

    /*void cseinsert(struct node* node, struct node* curr){
        pcse[node->vn].insert(pcse[curr->vn].begin(), pcse[curr->vn].end());
        for(int i=0;i<curr->nchild;i++){
            cseinsert(node, curr->children[i]);
        }
    }*/

    void optim(struct node* node, int todo = 1){
        if(node->nt == local_decl){
            struct node* child = node->children[1]->children[0];
            ssa[child->str] = child;
            child->vn = ++vncount;       
        }
        else if(node->nt == Equal){
            if(node->nchild == 2){
                optim(node->children[1], todo);
                string name = node->children[0]->children[0]->str;
                used.insert(name);
                ssa[name] = node->children[0]->children[0];
                node->children[0]->vn = ++vncount;
                node->children[0]->children[0]->vn = vncount; 
                if(node->children[1]->constant){
                    node->children[0]->constant = 1;
                    node->children[0]->value = node->children[1]->value;
                    node->children[0]->consflag = node->children[1]->consflag;
                    node->children[0]->children[0]->constant = 1;
                    node->children[0]->children[0]->value = node->children[1]->value;
                    node->children[0]->children[0]->consflag = node->children[1]->consflag;
                }
            }
        }
        else if(node->nt == Pexpr){
            if(node->children[0]->nt == identifier){
                string name = node->children[0]->children[0]->str;
                used.insert(name);
                //free(node->children[0]->children[0]);
                node->children[0]->children[0] = ssa[name];
                node->children[0]->vn = node->children[0]->children[0]->vn;
                node->vn = node->children[0]->vn;
                if(node->children[0]->children[0]->constant){
                    node->children[0]->constant = 1;
                    node->children[0]->value = node->children[0]->children[0]->value;
                    node->children[0]->consflag = node->children[0]->children[0]->consflag;
                }
                if(node->children[0]->constant){
                    node->constant = 1;
                    node->value = node->children[0]->value;
                    node->consflag = node->children[0]->consflag;
                    if(todo)
                        cpinsert(node->line, name, node->value);
                }
            }
            else if(node->children[0]->nt == integerLit){
                node->constant = 1;
                node->value = node->children[0]->children[0]->value;
            }
            else{
                optim(node->children[1], todo);
                node->vn = node->children[0]->vn;
                if(node->children[1]->constant){
                    node->constant = 1;
                    node->value = node->children[1]->value;
                    node->consflag = node->children[1]->consflag;
                }
            }
        }
        else if(node->nt == print_stmt){
            string name = node->children[4]->children[0]->str;
            used.insert(name);
            //free(node->children[4]->children[0]);
            node->children[4]->children[0] = ssa[name];
            if(node->children[4]->children[0]->constant)
                if(todo)
                    cpinsert(node->line, name, node->children[4]->children[0]->value);

        }
        else if(node->nt == scan_stmt){
            string name = node->children[5]->children[0]->str;
            used.insert(name);
            ssa[name] = node->children[5]->children[0];
            node->children[5]->vn = ++vncount;
            node->children[5]->children[0]->vn = vncount;
            if(node->children[5]->children[0]->constant)
                if(todo)
                    cpinsert(node->line, name, node->children[5]->children[0]->value);
        }
        else if(node->nt == integerLit){
            node->constant = 1;
            node->value = node->children[0]->value;
        }
        else if(node->nt == expr){
            if(node->nchild==1){
                optim(node->children[0], todo);
                if(node->children[0]->constant){
                    node->constant = 1;
                    node->value = node->children[0]->value;
                    node->consflag = node->children[0]->consflag;
                    if(node->children[0]->nt != Pexpr || (node->consflag && node->nchild != 1)){
                        //free(node->children[0]);
                        node->children[0] = cons_int(node->value, node->line);
                    }
                }
            }
            else{
                struct node* child = node->children[1];
                optim(child, todo);
                if(child->constant){
                    node->constant = 1;
                    if(child->nt == Not){
                        node->value = !child->value;
                    }
                    else if(child->nt == sub){
                        node->value = !child->value;
                    }
                    node->consflag = child->consflag;
                }
                //free(node->children[0]);
                //free(node->children[1]);
                node->children[0] = cons_int(node->value, node->line);
            }
        }
        else if(node->nt == add){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = node->children[0]->value + node->children[1]->value;
                node->consflag = 1;
            }
        }
        else if(node->nt == sub){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = node->children[0]->value - node->children[1]->value;
                node->consflag = 1;
            }
        }
        else if(node->nt == star){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = node->children[0]->value * node->children[1]->value;
                node->consflag = 1;
            }
        }
        else if(node->nt == Div){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = node->children[0]->value / node->children[1]->value;
                node->consflag = 1;
            }
        }
        else if(node->nt == mod){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = node->children[0]->value % node->children[1]->value;
                node->consflag = 1;
            }
        }
        else if(node->nt == orop){
            optim(node->children[0], todo);
            if(node->children[0]->constant){
                if(node->children[0]->value){
                    node->constant = 1;
                    node->value = 1;
                    node->consflag = 1;
                }      
                else{
                    optim(node->children[1], todo);
                    if(node->children[1]->constant){
                        node->constant = 1;
                        node->value = node->children[1]->value;
                        node->consflag = 1;
                    }
                }
            }
        }
        else if(node->nt == andop){
            optim(node->children[0], todo);
            if(node->children[0]->constant){
                if(!node->children[0]->value){
                    node->constant = 1;
                    node->value = 0;
                    node->consflag = 1;
                }      
                else{
                    optim(node->children[1], todo);
                    if(node->children[1]->constant){
                        node->constant = 1;
                        node->value = node->children[1]->value;
                        node->consflag = 1;
                    }
                }
            }
        }
        else if(node->nt == lesser){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = node->children[0]->value < node->children[1]->value;
                node->consflag = 1;
            }
        }
        else if(node->nt == Greater){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = node->children[0]->value > node->children[1]->value;
                node->consflag = 1;
            }
        }
        else if(node->nt == leqop){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = node->children[0]->value <= node->children[1]->value;
                node->consflag = 1;
            }
        }
        else if(node->nt == geqop){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = node->children[0]->value >= node->children[1]->value;
                node->consflag = 1;
            }
        }
        else if(node->nt == eqop){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = (node->children[0]->value == node->children[1]->value);
                node->consflag = 1;
            }
        }
        else if(node->nt == neqop){
            optim(node->children[0], todo);
            optim(node->children[1], todo);
            if(node->children[0]->constant && node->children[1]->constant){
                node->constant = 1;
                node->value = node->children[0]->value != node->children[1]->value;
                node->consflag = 1;
            }
        }
        else if(node->nt == if_stmt){
            if(node->nchild == 5){
                unordered_map < string, struct node* > tssa = ssa;
                optim(node->children[2], 0);
                if(node->children[2]->constant){
                    isif = 1;
                    if(node->children[2]->value){
                        nodecopy(node, node->children[4]->children[0]);
                        optim(node, todo);
                    }
                    else{
                        ifflag = 0;
                        nodecopy(node, cons_lex(epsilon));
                    }
                }
                else{
                    optim(node->children[4], todo);
                    for(auto i : tssa){
                        string key = i.first;
                        if(ssa.count(key)){
                            struct node* nod = ssa[key];
                            struct node* nod1 = i.second;
                            tssa[key] = phi(nod1, nod);
                        }
                    }
                    ssa = tssa;
                }
            }
            else if(node->nchild == 7){
                unordered_map < string, struct node* > tssa = ssa;
                unordered_map < string, struct node* > tssa2 = ssa;
                optim(node->children[2], 0);
                if(node->children[2]->constant){
                    isif = 1;
                    if(node->children[2]->value){
                        nodecopy(node, node->children[4]->children[0]);
                        optim(node, todo);
                    }
                    else{
                        ifflag = 0;
                        nodecopy(node, node->children[6]->children[0]);
                        optim(node, todo);
                    }
                }
                else{
                    optim(node->children[4], todo);
                    tssa2 = ssa;
                    ssa = tssa;
                    optim(node->children[6], todo);
                    for(auto i : tssa2){
                        string key = i.first;
                        if(ssa.count(key)){
                            struct node* nod = ssa[key];
                            struct node* nod1 = i.second;
                            tssa2[key] = phi(nod1, nod);
                        }
                    }
                    for(auto i : tssa){
                        string key = i.first;
                        if(tssa2.count(key)){
                            struct node* nod = tssa2[key];
                            tssa[key] = nod;
                        }
                    }
                    ssa = tssa;
                }
            }
        }
        else{
            for(int i=0;i<node->nchild;i++){
                optim(node->children[i], todo);
            }
        }
    }

    void valuen(struct node* nod){
        if(nod->nt == expr){
            if(nod->nchild==1){
                struct node* operato = nod->children[0];
                if(operato->nt != Pexpr){
                    struct node* op1 = operato->children[0];
                    struct node* op2 = operato->children[1];
                    valuen(op1);
                    valuen(op2);
                    if(csub.count(TS(op1->vn, operato->nt, op2->vn))){
                        nod->vn = csub[TS(op1->vn, operato->nt, op2->vn)];
                        operato->vn = nod->vn;
                        common.insert(nod->vn);
                        pcse[nod->vn].insert(nod->line);
                    }
                    else{
                        csub[TS(op1->vn, operato->nt, op2->vn)] = ++vncount;
                        nod->vn = vncount;
                        operato->vn = nod->vn;
                    }
                }
                else{
                    valuen(operato);
                    nod->vn = operato->vn;
                }
            }
            else{
                struct node* operato = nod->children[0];
                struct node* op1 = nod->children[1];
                valuen(op1);
                if(csub.count(TS(0, operato->nt, op1->vn))){
                    nod->vn = csub[TS(0, operato->nt, op1->vn)];
                    common.insert(nod->vn);
                    pcse[nod->vn].insert(nod->line);
                }
                else{
                    csub[TS(0, operato->nt, op1->vn)] = ++vncount;
                    nod->vn = vncount;
                }
            }
        }
        else if(nod->nt == Pexpr){
            if(nod->nchild==1){
                struct node* child = nod->children[0];
                /*if(child->nt == integerLit){
                    nod->vn = -stoi(child->children[0]->str);
                }*/
                if(child->nt == identifier && child->constant){
                    if(child->constant)
                        nod->vn = - child->value;
                }
                else if(child->children[0]->nt == intconst && child->children[0]->constant){
                    if(child->children[0]->consflag)
                        cfinsert2(child->children[0]->line, child->children[0]->value);
                    nod->vn = - child->children[0]->value;
                }
                else{
                    valuen(child);
                    nod->vn = child->vn;
                }
            }
            else{
                struct node* child = nod->children[1];
                valuen(child);
                nod->vn = child->vn;
            }
        }
        else if(nod->nt == if_stmt){
            //unordered_map < string, long long int > tcsub = csub;
            for(int i=0;i<nod->nchild;i++){
                valuen(nod->children[i]);
            }
            //csub = tcsub;
        }
        else{
            for(int i=0;i<nod->nchild;i++){
                valuen(nod->children[i]);
            }
        }
    }

    /*void allocmem(){
        for(auto i : common){
            mfile<<"subq $4, %rsp"<<endl;
            mfile<<"movl $0, (%rsp)"<<endl;
        }
    }*/

    void codegen(struct node* node){
        //mfile<<typenam[node->nt]<<endl;
        if(ArithB){
            if(node->nt == star && (node->children[1]->constant == 1 || node->children[0]->constant == 1)){
                int flag = (node->children[1]->constant == 1);
                codegen(node->children[!flag]);
                long long int n = node->children[flag]->value;
                if(ceil(log2(n)) == floor(log2(n))){
                    if(common.count(node->vn))
                        srinsert(node->vn, log2(n));
                    else
                        srinsert2(node->line, log2(n));
                    if(node->children[flag]->consflag && node->children[flag]->nchild != 1){
                        if(common.count(node->vn))
                            cfinsert(node->vn, n);
                        else
                            cfinsert2(node->line, n);
                    }
                    //cfinsert(node->line, n);
                    mfile<<"sall $"<<log2(n)<<", %eax"<<endl;
                }
                else{
                    pushl("%eax");
                    //mfile<<3<<endl;
                    codegen(node->children[flag]);
                    mfile<<"movl %eax, %ebx"<<endl;
                    popl("%eax");
                    if(node->nt == mod || node->nt == Div){
                        mfile<<"cltd"<<endl;
                        mfile<<typenam[node->nt]<<" %ebx"<<endl;
                    }
                    else{
                        mfile<<typenam[node->nt]<<" %ebx, %eax"<<endl;
                    }
                    if(node->nt == mod){
                        mfile<<"movl %edx, %eax"<<endl;
                    }
                }
            }
            else{
                codegen(node->children[0]);
                pushl("%eax");
                //mfile<<3<<endl;
                codegen(node->children[1]);
                mfile<<"movl %eax, %ebx"<<endl;
                popl("%eax");
                if(node->nt == mod || node->nt == Div){
                    mfile<<"cltd"<<endl;
                    mfile<<typenam[node->nt]<<" %ebx"<<endl;
                }
                else{
                    mfile<<typenam[node->nt]<<" %ebx, %eax"<<endl;
                }
                if(node->nt == mod){
                    mfile<<"movl %edx, %eax"<<endl;
                }
            }
        }
        else if(node->nt == incr_stmt){
            if(symtab.find(node->children[0]->children[0]->str) != symtab.end()){
                mfile<<"incl -"<<symtab[node->children[0]->children[0]->str]<<"(%rbp)"<<endl;
            }
            else{
                mfile<<"incl "<<getpara(paramtab[node->children[0]->children[0]->str])<<endl;
            }
        }
        else if(node->nt == decr_stmt){
            if(symtab.find(node->children[0]->children[0]->str) != symtab.end()){
                mfile<<"decl -"<<symtab[node->children[0]->children[0]->str]<<"(%rbp)"<<endl;
            }
            else{
                mfile<<"decl "<<getpara(paramtab[node->children[0]->children[0]->str])<<endl;
            }
        }
        else if(RelB){
            codegen(node->children[0]);
            pushl("%eax");
            //mfile<<4<<endl;
            codegen(node->children[1]);
            popl("%ebx");
            mfile<<"cmpl %eax, %ebx"<<endl;
            mfile<<typenam[node->nt]<<" %al"<<endl;
            mfile<<"movzbl %al, %eax"<<endl;
        }
        else if(Bin){
            codegen(node->children[0]);
            mfile<<"cmpl $0, %eax"<<endl;
            mfile<<"setne %al"<<endl;
            mfile<<"movzbl %al, %eax"<<endl;
            string lae = uniqlabel("end");
            if(node->nt == orop){
                mfile<<"cmpl $0, %eax"<<endl;
                mfile<<"jne "<<lae<<endl;
            }
            else{
                mfile<<"cmpl $0, %eax"<<endl;
                mfile<<"je "<<lae<<endl;
            }
            pushl("%eax");
            //mfile<<5<<endl;
            codegen(node->children[1]);
            popl("%ebx");
            mfile<<"cmpl $0, %eax"<<endl;
            mfile<<"setne %al"<<endl;
            mfile<<"movzbl %al, %eax"<<endl;
            mfile<<typenam[node->nt]<<" %ebx, %eax"<<endl;
            mfile<<"cmpl $0, %eax"<<endl;
            mfile<<"setg %al"<<endl;
            mfile<<"movzbl %al, %eax"<<endl;
            genlabel(lae);
        }
        else if(node->nt == expr){
            if(common.count(node->vn)){
                pcse[node->vn].insert(node->line);
                //cseinsert(node, node);
                if(symtab.find("%" + to_string(node->vn)) != symtab.end()){
                    mfile<<"movl -"<<symtab["%" + to_string(node->vn)]<<"(%rbp), %eax"<<endl;
                }
                else{
                    if(node->children[0]->nt != Pexpr){
                        offs += 4;
                        symtab["%" + to_string(node->vn)] = offs; 
                        if(insideif){
                            cseif.push_back(node);
                        }
                    }
                    if(node->nchild == 2){
                        codegen(node->children[1]);
                        if(node->children[0]->nt == sub){
                            mfile<<"negl %eax"<<endl;
                        }
                        else if(node->children[0]->nt == Not){
                            mfile<<"cmpl $0, %eax"<<endl;
                            mfile<<"sete %al"<<endl;
                            mfile<<"movzbl %al, %eax"<<endl;
                        }
                    }
                    else{
                        for(int i=0;i<node->nchild;i++){
                            codegen(node->children[i]);
                        }
                    }
                    if(node->children[0]->nt != Pexpr){
                        mfile<<"movl %eax, -"<<symtab["%" + to_string(node->vn)]<<"(%rbp)"<<endl;
                    }
                }
                /*for(int i=0;i<node->nchild;i++){
                    struct node* curr = node->children[i];
                    pcse[node->vn].insert(pcse[curr->vn].begin(), pcse[curr->vn].end());
                }*/
            }
            else if(node->nchild == 2){
                codegen(node->children[1]);
                if(node->children[0]->nt == sub){
                    mfile<<"negl %eax"<<endl;
                }
                else if(node->children[0]->nt == Not){
                    mfile<<"cmpl $0, %eax"<<endl;
                    mfile<<"sete %al"<<endl;
                    mfile<<"movzbl %al, %eax"<<endl;
                }
            }
            else if(node->nchild == 4){
                if(node->children[1]->nt == lbraces && node->children[0]->nt != Sizeof){
                    narg = funtab[node->children[0]->children[0]->str];
                    int temp = funtab[node->children[0]->children[0]->str];
                    codegen(node->children[2]);
                    mfile<<"call "<<node->children[0]->children[0]->str<<endl;
                    for(int i = 0; i<min(temp, 6); i++){
                        popl(getpara(i));
                    }
                    if(temp>6){
                        mfile<<"addq "<<"$"<<4*(temp - 6)<<", %rsp"<<endl;
                    }
                }
                else if(node->children[1]->nt == lbracket){
                    codegen(node->children[2]);
                    mfile<<"movl -"<<symtab[node->children[0]->children[0]->str]<<"(%rbp, %rax, 4), %eax"<<endl;
                }
                else{
                    string name = node->children[2]->children[0]->children[0]->str;
                    if(arraysize.find(name) != arraysize.end()){
                        mfile<<"movl $"<<arraysize[name]<<", %eax"<<endl;
                    }
                    else{
                        mfile<<"movl $4, %eax"<<endl;
                    }
                }
            }
            else{
                goto rest;
            }
        }
        else if(node->nt == if_stmt){
            insideif = 1;
            if(node->nchild == 5){
                string laf = uniqlabel("false");
                codegen(node->children[2]);
                mfile<<"cmpl $0, %eax"<<endl;
                mfile<<"je "<<laf<<endl;
                codegen(node->children[4]);
                mfile<<laf<<":"<<endl;
            }
            else if(node->nchild == 7){
                string laf = uniqlabel("false");
                string lae = uniqlabel("end");
                codegen(node->children[2]);
                mfile<<"cmpl $0, %eax"<<endl;
                mfile<<"je "<<laf<<endl;
                codegen(node->children[4]);
                mfile<<"jmp "<<lae<<endl;
                mfile<<laf<<":"<<endl;
                codegen(node->children[6]);
                mfile<<lae<<":"<<endl;
            }
            insideif = 0;
            for(auto node : cseif){
                if(node->nchild == 2){
                    codegen(node->children[1]);
                    if(node->children[0]->nt == sub){
                        mfile<<"negl %eax"<<endl;
                    }
                    else if(node->children[0]->nt == Not){
                        mfile<<"cmpl $0, %eax"<<endl;
                        mfile<<"sete %al"<<endl;
                        mfile<<"movzbl %al, %eax"<<endl;
                    }
                }
                else{
                    for(int i=0;i<node->nchild;i++){
                        codegen(node->children[i]);
                    }
                }
                mfile<<"movl %eax, -"<<symtab["%" + to_string(node->vn)]<<"(%rbp)"<<endl;
            }
        }
        else if(node->nt == while_stmt){
            string start = uniqlabel("start");
            string end = uniqlabel("end");
            genlabel(start);
            string laf = uniqlabel("false");
            codegen(node->children[2]);
            mfile<<"cmpl $0, %eax"<<endl;
            mfile<<"je "<<laf<<endl;
            codegen(node->children[4]);
            gotol(start);
            mfile<<laf<<":"<<endl;
        }
        else if(node->nt == Equal){
            if(node->nchild == 2){
                codegen(node->children[1]);
                if(symtab.find(node->children[0]->children[0]->str) != symtab.end()){
                    //mfile<<child->str<<endl;
                    mfile<<"movl %eax, -"<<symtab[node->children[0]->children[0]->str]<<"(%rbp)"<<endl;
                }
                else{
                    mfile<<"movl %eax, "<<getpara(paramtab[node->children[0]->children[0]->str])<<endl;
                }
            }
            else{
                codegen(node->children[2]);
                pushl("%eax");
                codegen(node->children[4]);
                popl("%ebx");
                mfile<<"movl %eax, -"<<symtab[node->children[0]->children[0]->str]<<"(%rbp, %rbx, 4)"<<endl;
            }
        }
        else if(node->nt == intconst){
            if(node->consflag){
                if(common.count(node->vn))
                    cfinsert(node->vn, node->value);
                else
                    cfinsert2(node->line, node->value);
            }
            genconst(node->str);
        }
        else if(node->nt == arg_list){
            if(node->nchild == 3){
                codegen(node->children[2]);
                if(narg>6){
                    pushl("%eax");
                    //mfile<<1<<endl;
                }
                else{
                    pushl(getpara(narg-1));
                    mfile<<"movl %eax, "<<getpara(narg-1)<<endl;
                }
                narg--;
                codegen(node->children[0]);   
            }
            else{
                codegen(node->children[0]);
                pushl(getpara(narg-1));
                mfile<<"movl %eax, "<<getpara(narg-1)<<endl;
                //mfile<<2<<endl;
            }
        }
        else if(node->nt == func_decl){
            offs = 0;
            soffs = 0;
            npara = 0;
            retu = 1;
            symtab.clear();
            paramtab.clear();
            arraysize.clear();
            if(node->children[1]->children[0]->str == "main"){
                genlabel(".LC0");
                mfile<<".string	\"%d\\n\""<<endl;
                genlabel(".LC1");
                mfile<<".string	\"%d\""<<endl;
            }
            mfile<<".text"<<endl;
            mfile<<".globl	"<< node->children[1]->children[0]->str <<endl;
            mfile<<".type	"<< node->children[1]->children[0]->str <<", @function"<<endl;
            genlabel(node->children[1]->children[0]->str);
            enter();
            codegen(node->children[3]);
            funtab[node->children[1]->children[0]->str] = npara;
            //mfile<<npara<<node->children[1]->children[0]->str<<endl;
            codegen(node->children[5]);
            if(retu){
                mfile<<"movl	$0, %eax"<<endl;
                mfile<<"leave"<<endl;
                mfile<<"ret"<<endl;
            }
        }
        else if(node->nt == local_decl){
            if(node->nchild == 3){
                string name = node->children[1]->children[0]->str;
                if(used.count(name)){
                    offs += 4;
                    soffs += 4;
                    symtab[name] = offs; 
                    mfile<<"subq $4, %rsp"<<endl;
                    mfile<<"movl $0, (%rsp)"<<endl;
                }
                else{
                    unused.push_back(name);
                }
            }
            else{
                int size = stoi(node->children[3]->children[0]->children[0]->children[0]->str);
                offs += 4 * size;
                soffs += 4 * size;
                mfile<<"subq $"<<4*size<<", %rsp"<<endl;
                symtab[node->children[1]->children[0]->str] = offs; 
                arraysize[node->children[1]->children[0]->str] = 4 * size;
            }
        }
        else if(node->nt == Pexpr && node->children[0]->nt == identifier){
            struct node* child = node->children[0]->children[0];
            if(symtab.find(child->str) != symtab.end()){
                //mfile<<child->str<<endl;
                mfile<<"movl -"<<symtab[child->str]<<"(%rbp), %eax"<<endl;
            }
            else{
                mfile<<"movl "<<getpara(paramtab[child->str])<<", %eax"<<endl;
            }
        }
        else if(node->nt == param){
            struct node* child = node->children[1]->children[0];
            paramtab[child->str] = npara;
            npara++;
        }
        else if(node->nt == print_stmt){
            struct node* child = node->children[4]->children[0];
            if(symtab.find(child->str) != symtab.end()){
                mfile<<"movl -"<<symtab[child->str]<<"(%rbp), %eax"<<endl;
            }
            else{
                mfile<<"movl "<<getpara(paramtab[child->str])<<", %eax"<<endl;
            }
            /*for(int i=0; i<6; i++){
                pushl(getpara(i));
            }*/
            mfile<<"movl %eax, %esi"<<endl;
            mfile<<"leaq	.LC0(%rip), %rdi"<<endl;
            mfile<<"movl	$0, %eax"<<endl;
            mfile<<"call	printf@PLT"<<endl;
            /*for(int i=5; i>=0; i--){
                popl(getpara(i));
            }*/
        }
        else if(node->nt == scan_stmt){
            struct node* child = node->children[5]->children[0];
            if(symtab.find(child->str) != symtab.end()){
                mfile<<"leaq -"<<symtab[child->str]<<"(%rbp), %rsi"<<endl;
            }
            else{
                mfile<<"leaq "<<getpara(paramtab[child->str])<<", %rsi"<<endl;
            }
            /*for(int i=0; i<6; i++){
                pushl(getpara(i));
            }*/
            mfile<<"leaq	.LC1(%rip), %rdi"<<endl;
            mfile<<"subq $"<< 16 - (soffs % 16)<<", %rsp"<<endl;
            mfile<<"movl	$0, %eax"<<endl;
            mfile<<"call	scanf@PLT"<<endl;
            mfile<<"addq $"<< 16 - (soffs % 16)<<", %rsp"<<endl;
            /*for(int i=5; i>=0; i--){
                popl(getpara(i));
            }*/
        }
        else if(node->nt == return_stmt){
            if(node->nchild == 3){
                retu = 0;
                codegen(node->children[1]);
                mfile<<"leave"<<endl;
                mfile<<"ret"<<endl;
            }
        }
        else{
            rest:
            for(int i=0;i<node->nchild;i++){
                codegen(node->children[i]);
            }
        }
    }

    void printing(){
        ofstream myfile;
        myfile.open ("summary.txt");
        myfile<<"unused-vars"<<endl;
        for(auto i : unused){
            myfile<<i<<endl;
        }
        myfile<<endl;
        myfile<<"if-simpl"<<endl;
        if(isif)
            myfile<<ifflag<<endl;
        myfile<<endl;
        myfile<<"strength-reduction"<<endl;
        for(auto i : sred){
            for(auto j : pcse[i.first]){
                srinsert2(j, i.second);
            }
        }
        for(auto i : sred2){
            myfile<<i.first<<" "<<i.second<<endl;
        }
        myfile<<endl;
        myfile<<"constant-folding"<<endl;
        for(auto i : cfold){
            for(auto j : pcse[i.first]){
                cfinsert2(j, i.second);
            }
        }
        for(auto i : cfold2){
            myfile<<i.first<<" "<<i.second<<endl;
        }
        myfile<<endl;
        myfile<<"constant-propagation"<<endl;
        for(auto i : cprop){
            unordered_set < string > printed;
            sort(i.second.begin(), i.second.end(), cmpBy);
            myfile<<i.first;
            for(auto j : i.second){
                if(printed.count(j.first)==0){
                    myfile<<" "<<j.first<<" "<<j.second;
                    printed.insert(j.first);
                }
            }
            myfile<<endl;
        }
        myfile<<endl;
        myfile<<"cse"<<endl;
        for(auto i : pcse){
            for(auto j : i.second)
                myfile<<j<<" ";
            myfile<<endl;
        }
        //myfile<<endl;
        /*for(auto i : symtab){
            myfile<<i.first<<" "<<i.second<<endl;
        }*/
        myfile.close();
    }

%}

%%

program
    : decl_list {$$ = cons_rep(program, 1, new struct node*[1] {$1});optim($$);valuen($$);codegen($$);printing();}
    ; 

decl_list
    : decl_list decl    {$$ = cons_rep(decl_list, 2, new struct node*[2] {$1, $2});}
    | decl  {$$ = cons_rep(decl_list, 1, new struct node*[1] {$1});}
    ;

decl
    : var_decl  {$$ = cons_rep(decl, 1, new struct node*[1] {$1});} 
    | func_decl {$$ = cons_rep(decl, 1, new struct node*[1] {$1});}
    | struct_decl   {$$ = cons_rep(decl, 1, new struct node*[1] {$1});}
    ;

struct_decl
    : STRUCT identifier LCURLY local_decls RCURLY SEMICOLON  {$$ = cons_rep(struct_decl, 6, new struct node*[6] {cons_lex(Struct), $2, cons_lex(lcurly), $4, cons_lex(rcurly), cons_lex(semicolon)});}
    ;

var_decl
    : type_spec identifier SEMICOLON    {$$ = cons_rep(var_decl, 3, new struct node*[3] {$1, $2, cons_lex(semicolon)});}
    | type_spec identifier COMMA var_decl   {$$ = cons_rep(var_decl, 4, new struct node*[4] {$1, $2, cons_lex(comma), $4});}
    | type_spec identifier LBRACKET integerLit RBRACKET SEMICOLON   {$$ = cons_rep(var_decl, 6, new struct node*[6] {$1, $2, cons_lex(lbracket), $4, cons_lex(rbracket), cons_lex(semicolon)});}
    | type_spec identifier LBRACKET integerLit RBRACKET COMMA var_decl  {$$ = cons_rep(var_decl, 7, new struct node*[7] {$1, $2, cons_lex(lbracket), $4, cons_lex(rbracket), cons_lex(comma), $7});}
    ;

type_spec
    : extern_spec VOID {$$ = cons_rep(type_spec, 2, new struct node*[2] {$1, cons_lex(Void)});}
    | extern_spec INT   {$$ = cons_rep(type_spec, 2, new struct node*[2] {$1, cons_lex(Int)});}
    | extern_spec FLOAT {$$ = cons_rep(type_spec, 2, new struct node*[2] {$1, cons_lex(Float)});}
    | extern_spec VOID STAR {$$ = cons_rep(type_spec, 3, new struct node*[3] {$1, cons_lex(Void), cons_lex(star)});}
    | extern_spec INT STAR  {$$ = cons_rep(type_spec, 3, new struct node*[3] {$1, cons_lex(Int), cons_lex(star)});}
    | extern_spec FLOAT STAR    {$$ = cons_rep(type_spec, 3, new struct node*[3] {$1, cons_lex(Float), cons_lex(star)});}
    | STRUCT identifier {$$ = cons_rep(type_spec, 2, new struct node*[2] {cons_lex(Struct), $2});}  
    | STRUCT identifier STAR    {$$ = cons_rep(type_spec, 3, new struct node*[3] {cons_lex(Struct), $2, cons_lex(star)});}
    ;   

extern_spec
    : EXTERN    {$$ = cons_rep(extern_spec, 1, new struct node*[1] {cons_lex(Extern)});}
    | /*empty*/ {$$ = cons_rep(extern_spec, 1, new struct node*[1] {cons_lex(epsilon)});}
    ;

func_decl
    : type_spec identifier LBRACES params RBRACES compound_stmt {$$ = cons_rep(func_decl, 6, new struct node*[6] {$1, $2, cons_lex(lbraces), $4, cons_lex(rbraces), $6});}
    ;

params
    : param_list    {$$ = cons_rep(params, 1, new struct node*[1] {$1});}
    | /*empty*/ {$$ = cons_rep(params, 1, new struct node*[1] {cons_lex(epsilon)});}
    ;

param_list
    : param_list COMMA param    {$$ = cons_rep(param_list, 3, new struct node*[3] {$1, cons_lex(comma), $3});}
    | param {$$ = cons_rep(param_list, 1, new struct node*[1] {$1});}
    ;

param
    : type_spec identifier  {$$ = cons_rep(param, 2, new struct node*[2] {$1, $2});}
    | type_spec identifier LBRACKET RBRACKET    {$$ = cons_rep(param, 4, new struct node*[4] {$1, $2, cons_lex(lbracket), cons_lex(rbracket)});}
    ;

stmt_list
    : stmt_list stmt   {$$ = cons_rep(stmt_list, 2, new struct node*[2] {$1, $2});}
    | stmt  {$$ = cons_rep(stmt_list, 1, new struct node*[1] {$1});}
    ;

stmt
    : assign_stmt   {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | compound_stmt {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | if_stmt   {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | while_stmt    {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | switch_stmt   {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | return_stmt   {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | break_stmt    {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | continue_stmt {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | dowhile_stmt  {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | print_stmt    {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | scan_stmt    {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | incr_stmt {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    | decr_stmt {$$ = cons_rep(stmt, 1, new struct node*[1] {$1});}
    ;

while_stmt
    : WHILE LBRACES expr RBRACES stmt   {$$ = cons_rep(while_stmt, 5, new struct node*[5] {cons_lex(While), cons_lex(lbraces), $3, cons_lex(rbraces), $5});}
    ;

dowhile_stmt
    : DO stmt WHILE LBRACES expr RBRACES SEMICOLON  {$$ = cons_rep(dowhile_stmt, 7, new struct node*[7] {cons_lex(Do), $2, cons_lex(While), cons_lex(lbraces), $5, cons_lex(rbraces), cons_lex(semicolon)});}
    ;

print_stmt
    : PRINTF LBRACES format_specifier COMMA identifier RBRACES SEMICOLON    {$$ = cons_rep(print_stmt, 7, new struct node*[7] {cons_lex(Printf), cons_lex(lbraces), $3, cons_lex(comma), $5, cons_lex(rbraces), cons_lex(semicolon)});}
    ;

scan_stmt
    : SCANF LBRACES format_specifier COMMA AND identifier RBRACES SEMICOLON    {$$ = cons_rep(scan_stmt, 8, new struct node*[8] {cons_lex(Scanf), cons_lex(lbraces), $3, cons_lex(comma), cons_lex(And), $6, cons_lex(rbraces), cons_lex(semicolon)});}
    ;

format_specifier
    : FRMT_SPEC {$$ = cons_rep(format_specifier, 1, new struct node*[1] {cons_lex(frmt_spec)});}
    ;

compound_stmt  
    : LCURLY local_decls stmt_list RCURLY   {$$ = cons_rep(compound_stmt, 4, new struct node*[4] {cons_lex(lcurly), $2, $3, cons_lex(rcurly)});}
    ;

local_decls
    : local_decls local_decl  {$$ = cons_rep(local_decls, 2, new struct node*[2] {$1, $2});}
    | /*empty*/ {$$ = cons_rep(local_decls, 1, new struct node*[1] {cons_lex(epsilon)});}
    ;

local_decl
    : type_spec identifier SEMICOLON    {$$ = cons_rep(local_decl, 3, new struct node*[3] {$1, $2, cons_lex(semicolon)});}
    | type_spec identifier LBRACKET expr RBRACKET SEMICOLON {$$ = cons_rep(local_decl, 6, new struct node*[6] {$1, $2, cons_lex(lbracket), $4, cons_lex(rbracket), cons_lex(semicolon)});}
    ;

if_stmt
    : IF LBRACES expr RBRACES stmt  {$$ = cons_rep(if_stmt, 5, new struct node*[5] {cons_lex(If), cons_lex(lbraces), $3, cons_lex(rbraces), $5});}
    | IF LBRACES expr RBRACES stmt ELSE stmt    {$$ = cons_rep(if_stmt, 7, new struct node*[7] {cons_lex(If), cons_lex(lbraces), $3, cons_lex(rbraces), $5, cons_lex(Else), $7});}
    ;

return_stmt
    : RETURN SEMICOLON  {$$ = cons_rep(return_stmt, 2, new struct node*[2] {cons_lex(Return), cons_lex(semicolon)});}
    | RETURN expr SEMICOLON {$$ = cons_rep(return_stmt, 3, new struct node*[3] {cons_lex(Return), $2, cons_lex(semicolon)});}
    ;

break_stmt
    : BREAK SEMICOLON   {$$ = cons_rep(break_stmt, 2, new struct node*[2] {cons_lex(Break), cons_lex(semicolon)});}
    ;

continue_stmt
    : CONTINUE SEMICOLON    {$$ = cons_rep(continue_stmt, 2, new struct node*[2] {cons_lex(Continue), cons_lex(semicolon)});}
    ;

switch_stmt
    : SWITCH LBRACES expr RBRACES LCURLY compound_case default_case RCURLY  {$$ = cons_rep(switch_stmt, 8, new struct node*[8] {cons_lex(Switch), cons_lex(lbraces), $3, cons_lex(rbraces), cons_lex(lcurly), $6, $7, cons_lex(rcurly)});}
    ;

compound_case 
    : single_case compound_case {$$ = cons_rep(compound_case, 2, new struct node*[2] {$1, $2});}
    | single_case   {$$ = cons_rep(compound_case, 1, new struct node*[1] {$1});}
    ;

single_case
    : CASE integerLit COLON stmt_list   {$$ = cons_rep(single_case, 4, new struct node*[4] {cons_lex(Case), $2, cons_lex(colon), $4});}
    ;

default_case
    : DEFAULT COLON stmt_list   {$$ = cons_rep(default_case, 3, new struct node*[3] {cons_lex(Default), cons_lex(colon), $3});}
    ;

assign_stmt
    : identifier EQUAL expr SEMICOLON   {$$ = cons_rep(assign_stmt, 2, new struct node*[2] {cons_rep(Equal, 2, new struct node*[2] {$1, $3}), cons_lex(semicolon)});}
    | identifier LBRACKET expr RBRACKET EQUAL expr SEMICOLON    {$$ = cons_rep(assign_stmt, 2, new struct node*[2] {cons_rep(Equal, 5, new struct node*[5] {$1, cons_lex(lbracket), $3, cons_lex(rbracket), $6}), cons_lex(semicolon)});}
    | identifier POIOP identifier EQUAL expr SEMICOLON  {$$ = cons_rep(assign_stmt, 2, new struct node*[2] {cons_rep(Equal, 4, new struct node*[4] {$1, cons_lex(poiop), $3, $5}), cons_lex(semicolon)});}
    | identifier DOT identifier EQUAL expr SEMICOLON    {$$ = cons_rep(assign_stmt, 2, new struct node*[2] {cons_rep(Equal, 4, new struct node*[4] {$1, cons_lex(dot), $3, $5}), cons_lex(semicolon)});}
    ;

incr_stmt
    : identifier INCOP SEMICOLON    {$$ = cons_rep(incr_stmt, 3, new struct node*[3] {$1, cons_lex(incop), cons_lex(semicolon)});}
    ;

decr_stmt
    : identifier DECOP SEMICOLON    {$$ = cons_rep(decr_stmt, 3, new struct node*[3] {$1, cons_lex(decop), cons_lex(semicolon)});}
    ;

expr
    : Pexpr LESSER Pexpr    {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(lesser, 2, new struct node*[2] {$1, $3})});}
    | Pexpr GREATER Pexpr   {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(Greater, 2, new struct node*[2] {$1, $3})});}
    | Pexpr LEQOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(leqop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr GEQOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(geqop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr OROP Pexpr  {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(orop, 2, new struct node*[2] {$1, $3})});}
    | SIZEOF LBRACES Pexpr RBRACES  {$$ = cons_rep(expr, 4, new struct node*[4] {cons_lex(Sizeof), cons_lex(lbraces), $3, cons_lex(rbraces)});}
    | Pexpr EQOP Pexpr  {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(eqop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr NEQOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(neqop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr COMOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(comop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr ANDOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(andop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr POIOP Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(poiop, 2, new struct node*[2] {$1, $3})});}
    | Pexpr ADD Pexpr   {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(add, 2, new struct node*[2] {$1, $3})});}
    | Pexpr SUB Pexpr   {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(sub, 2, new struct node*[2] {$1, $3})});}
    | Pexpr STAR Pexpr  {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(star, 2, new struct node*[2] {$1, $3})});}
    | Pexpr DIV Pexpr   {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(Div, 2, new struct node*[2] {$1, $3})});}
    | Pexpr MOD Pexpr   {$$ = cons_rep(expr, 1, new struct node*[1] {cons_rep(mod, 2, new struct node*[2] {$1, $3})});}
    | NOT Pexpr {$$ = cons_rep(expr, 2, new struct node*[2] {cons_lex(Not), $2});}
    | SUB Pexpr {$$ = cons_rep(expr, 2, new struct node*[2] {cons_lex(sub), $2});}
    | ADD Pexpr {$$ = cons_rep(expr, 2, new struct node*[2] {cons_lex(add), $2});}
    | STAR Pexpr    {$$ = cons_rep(expr, 2, new struct node*[2] {cons_lex(star), $2});}
    | AND Pexpr {$$ = cons_rep(expr, 2, new struct node*[2] {cons_lex(And), $2});}
    | Pexpr {$$ = cons_rep(expr, 1, new struct node*[1] {$1});}
    | identifier LBRACES args RBRACES   {$$ = cons_rep(expr, 4, new struct node*[4] {$1, cons_lex(lbraces), $3, cons_lex(rbraces)});}
    | identifier LBRACKET expr RBRACKET {$$ = cons_rep(expr, 4, new struct node*[4] {$1, cons_lex(lbracket), $3, cons_lex(rbracket)});}
    ;

Pexpr
    : integerLit    {$$ = cons_rep(Pexpr, 1, new struct node*[1] {$1});}
    | floatLit  {$$ = cons_rep(Pexpr, 1, new struct node*[1] {$1});}
    | identifier    {$$ = cons_rep(Pexpr, 1, new struct node*[1] {$1});}
    | LBRACES expr RBRACES  {$$ = cons_rep(Pexpr, 3, new struct node*[3] {cons_lex(lbraces), $2, cons_lex(rbraces)});}
    ;

arg_list
    : arg_list COMMA expr  {$$ = cons_rep(arg_list, 3, new struct node*[3] {$1, cons_lex(comma), $3});}
    | expr  {$$ = cons_rep(arg_list, 1, new struct node*[1] {$1});}
    ;

args 
    : arg_list  {$$ = cons_rep(args, 1, new struct node*[1] {$1});}
    | /*empty*/ {$$ = cons_rep(args, 1, new struct node*[1] {cons_lex(epsilon)});}
    ;

integerLit
    : INTCONST  {$$ = cons_rep(integerLit, 1, new struct node*[1] {cons_lexstr(intconst, yytext)});}
    ;

floatLit
    : FLOATCONST    {$$ = cons_rep(floatLit, 1, new struct node*[1] {cons_lexstr(floatconst, yytext)});}
    ;

identifier
    : ID    {$$ = cons_rep(identifier, 1, new struct node*[1] {cons_lexstr(id, yytext)});}
    ;

%%

extern FILE *yyin;

void yyerror(char * s) {
    syntax = 1;
}

int main() {
    mfile.open ("assembly.s");
    yyparse();
    mfile.close();
    if(syntax!=0){
        printf("syntax error\n");
        return 0;
    }
    return 0;
}